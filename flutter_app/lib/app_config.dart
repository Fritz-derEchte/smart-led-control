/// Runtime configuration for broker and device.
///
/// Values must match `esp32/src/config.h` on the firmware side.
class AppConfig {
  static const String mqttHost = 'broker.hivemq.com';
  static const int mqttPort = 1883;

  /// Must be identical to `DEVICE_ID` in the firmware.
  static const String deviceId = 'htl-cca-volker-esp32';

  static String get topicBase => 'htl/smartled/$deviceId';
  static String get topicCmd => '$topicBase/cmd';
  static String get topicState => '$topicBase/state';
  static String get topicSensor => '$topicBase/sensor';
  static String get topicOnline => '$topicBase/online';
}
