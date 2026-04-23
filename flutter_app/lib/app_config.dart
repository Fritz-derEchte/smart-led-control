/// Runtime configuration for broker and device.
///
/// Values must match `esp32/src/config.h` on the firmware side.
class AppConfig {
  // Some mobile carriers hijack broker.hivemq.com's DNS to 127.0.0.1;
  // fall back to a direct AWS IP (known A record for broker.hivemq.com).
  static const String mqttHost = '35.157.221.203';
  static const int mqttPort = 1883;

  /// Must be identical to `DEVICE_ID` in the firmware.
  static const String deviceId = 'htl-cca-volker-esp32';

  static String get topicBase => 'htl/smartled/$deviceId';
  static String get topicCmd => '$topicBase/cmd';
  static String get topicState => '$topicBase/state';
  static String get topicSensor => '$topicBase/sensor';
  static String get topicOnline => '$topicBase/online';
}
