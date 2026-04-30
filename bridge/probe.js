// Quick diagnostic: connect to the broker and dump online + state retained
// messages for the configured device. Exits after 5s.
const mqtt = require('mqtt');

const HOST = '35.157.221.203';
const DEVICE = 'htl-cca-volker-esp32';
const BASE = `htl/smartled/${DEVICE}`;

const client = mqtt.connect(`mqtt://${HOST}:1883`, {
  clientId: 'diag-' + Math.random().toString(16).slice(2),
  reconnectPeriod: 0,
  connectTimeout: 5000,
});

const seen = {};
client.on('connect', () => {
  console.log('[broker] connected');
  client.subscribe([`${BASE}/online`, `${BASE}/state`, `${BASE}/sensor`], { qos: 0 });
});
client.on('message', (t, p, pkt) => {
  const v = p.toString();
  console.log(`[msg] ${t} (retained=${pkt.retain}): ${v}`);
  seen[t] = v;
});
client.on('error', (e) => console.log('[err]', e.message));

setTimeout(() => {
  console.log('--- summary ---');
  console.log('online:', seen[`${BASE}/online`] ?? '(no retained message)');
  console.log('state :', seen[`${BASE}/state`]  ?? '(no retained message)');
  console.log('sensor:', seen[`${BASE}/sensor`] ?? '(no retained message)');
  client.end(true);
  process.exit(0);
}, 5000);
