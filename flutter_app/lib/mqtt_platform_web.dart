import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

/// The Flutter web build cannot talk raw TCP, so it needs a WebSocket
/// endpoint. Most mobile hotspots block the public HiveMQ WS ports
/// (8000/8884), so we point the browser at a local Node bridge that
/// forwards over plain TCP:1883 (which the carriers do allow).
///
/// Start the bridge with `npm --prefix ../bridge start` before running the
/// web app.
MqttClient createMqttClient(String clientId) {
  final client = MqttBrowserClient.withPort(
    'ws://localhost:9001/mqtt',
    clientId,
    9001,
  );
  client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
  return client;
}
