// Minimal WebSocket <-> TCP bridge so the Flutter web app can reach the
// HiveMQ public broker even when the upstream network blocks outbound
// port 8000/8884 (mobile hotspot restriction).
//
//   Browser  --ws--> localhost:9001/mqtt  --tcp--> broker.hivemq.com:1883
//
// Run with:  node bridge.js

const http = require('http');
const https = require('https');
const net = require('net');
const { WebSocketServer } = require('ws');

const LISTEN_PORT = 9001;
const UPSTREAM_HOST = 'broker.hivemq.com';
const UPSTREAM_PORT = 1883;

// Resolve via Cloudflare DNS-over-HTTPS — the shell's built-in DNS is
// sometimes blocked on restricted networks, but :443 HTTPS is always open.
function dohResolve(host) {
  return new Promise((resolve, reject) => {
    const req = https.request({
      host: 'cloudflare-dns.com',
      path: `/dns-query?name=${encodeURIComponent(host)}&type=A`,
      headers: { accept: 'application/dns-json' },
      timeout: 8000,
    }, (res) => {
      let body = '';
      res.on('data', (c) => (body += c));
      res.on('end', () => {
        try {
          const j = JSON.parse(body);
          const ips = (j.Answer || []).filter((a) => a.type === 1).map((a) => a.data);
          if (!ips.length) return reject(new Error('no A records'));
          resolve(ips);
        } catch (e) { reject(e); }
      });
    });
    req.on('error', reject);
    req.on('timeout', () => req.destroy(new Error('doh timeout')));
    req.end();
  });
}

let cachedIps = null;
let cachedAt = 0;
async function resolveUpstream() {
  const now = Date.now();
  if (cachedIps && now - cachedAt < 5 * 60_000) return cachedIps;
  const ips = await dohResolve(UPSTREAM_HOST);
  cachedIps = ips;
  cachedAt = now;
  console.log(`[dns] ${UPSTREAM_HOST} -> ${ips.join(', ')}`);
  return ips;
}

function connectFirst(ips, port) {
  return new Promise((resolve, reject) => {
    let idx = 0;
    const tryNext = () => {
      if (idx >= ips.length) return reject(new Error('all upstream IPs failed'));
      const ip = ips[idx++];
      const sock = net.connect(port, ip);
      sock.once('connect', () => { sock.removeAllListeners('error'); resolve({ sock, ip }); });
      sock.once('error', () => { try { sock.destroy(); } catch (_) {} tryNext(); });
    };
    tryNext();
  });
}

const server = http.createServer();
const wss = new WebSocketServer({ server, path: '/mqtt', handleProtocols: () => 'mqtt' });

wss.on('connection', async (ws, req) => {
  const tag = `[${new Date().toISOString()}] ${req.socket.remoteAddress}`;
  console.log(`${tag} ws open`);

  let ips;
  try {
    ips = await resolveUpstream();
  } catch (e) {
    console.log(`${tag} dns error: ${e.message}`);
    ws.close();
    return;
  }

  let tcp, chosenIp;
  try {
    const r = await connectFirst(ips, UPSTREAM_PORT);
    tcp = r.sock;
    chosenIp = r.ip;
    console.log(`${tag} tcp connected ${chosenIp}:${UPSTREAM_PORT}`);
  } catch (e) {
    console.log(`${tag} upstream dial error: ${e.message}`);
    ws.close();
    return;
  }

  ws.on('message', (data, isBinary) => {
    const buf = isBinary ? data : Buffer.from(data);
    console.log(`${tag} ws->tcp ${buf.length}B [${buf.slice(0, 6).toString('hex')}]`);
    if (!tcp.destroyed) tcp.write(buf);
  });
  tcp.on('data', (data) => {
    console.log(`${tag} tcp->ws ${data.length}B [${data.slice(0, 6).toString('hex')}]`);
    if (ws.readyState === ws.OPEN) ws.send(data, { binary: true });
  });

  const close = (why) => {
    console.log(`${tag} close (${why})`);
    try { ws.close(); } catch (_) {}
    try { tcp.destroy(); } catch (_) {}
  };
  ws.on('close', () => close('ws'));
  ws.on('error', (e) => close('ws-err ' + e.message));
  tcp.on('end', () => close('tcp-end'));
  tcp.on('error', (e) => close('tcp-err ' + e.message));
});

server.listen(LISTEN_PORT, '127.0.0.1', () => {
  console.log(`MQTT bridge listening on ws://localhost:${LISTEN_PORT}/mqtt -> tcp://${UPSTREAM_HOST}:${UPSTREAM_PORT}`);
});
