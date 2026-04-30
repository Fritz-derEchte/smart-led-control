// Listen to the entire htl/smartled/# tree for 8s and dump anything seen.
const mqtt = require('mqtt');
const HOST = '35.157.221.203';

const client = mqtt.connect(`mqtt://${HOST}:1883`, {
  clientId: 'diag-wild-' + Math.random().toString(16).slice(2),
  reconnectPeriod: 0,
  connectTimeout: 5000,
});

client.on('connect', () => {
  console.log('[broker] connected, subscribing to htl/smartled/#');
  client.subscribe('htl/smartled/#', { qos: 0 });
});
client.on('message', (t, p, pkt) => {
  console.log(`[${new Date().toISOString().slice(11, 19)}] retained=${pkt.retain} ${t} -> ${p.toString().slice(0, 120)}`);
});
client.on('error', (e) => console.log('[err]', e.message));

setTimeout(() => { client.end(true); process.exit(0); }, 8000);
