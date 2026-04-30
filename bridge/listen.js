// Long-running listener — prints every message on the device's topics.
// Stop with Ctrl+C.
const mqtt = require('mqtt');
const HOST = '35.157.221.203';
const DEVICE = 'htl-cca-volker-esp32';
const BASE = `htl/smartled/${DEVICE}`;

const client = mqtt.connect(`mqtt://${HOST}:1883`, {
  clientId: 'listen-' + Math.random().toString(16).slice(2),
  reconnectPeriod: 2000,
});
client.on('connect', () => {
  console.log('[broker] connected, listening on', BASE + '/#');
  client.subscribe(BASE + '/#', { qos: 0 });
});
client.on('message', (t, p, pkt) => {
  const tag = pkt.retain ? 'retained' : 'live    ';
  console.log(`[${new Date().toISOString().slice(11, 19)}] ${tag} ${t} -> ${p.toString().slice(0, 200)}`);
});
client.on('error', (e) => console.log('[err]', e.message));
client.on('reconnect', () => console.log('[broker] reconnecting…'));
