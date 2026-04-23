import 'package:mqtt_client/mqtt_client.dart';

/// Stub — actual implementation is picked via conditional imports
/// (`mqtt_platform_io.dart` for mobile/desktop, `mqtt_platform_web.dart`
/// for Flutter web).
MqttClient createMqttClient(String clientId) =>
    throw UnsupportedError('No platform-specific MQTT client available.');
