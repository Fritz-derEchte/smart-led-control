import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'app_config.dart';
import 'device_state.dart';
import 'mqtt_platform.dart'
    if (dart.library.io) 'mqtt_platform_io.dart'
    if (dart.library.js_interop) 'mqtt_platform_web.dart';

enum BrokerStatus { disconnected, connecting, connected }

/// Owns the MQTT connection, exposes three listenables for the UI:
///   - [brokerStatus]  : connection to HiveMQ
///   - [deviceOnline]  : online/offline LWT of the ESP32
///   - [ledState]      : last known LED state reported by the ESP32
///   - [sensor]        : last DHT22 reading (or null)
class MqttService {
  MqttService() {
    _client.logging(on: false);
    _client.keepAlivePeriod = 20;
    _client.autoReconnect = true;
    _client.resubscribeOnAutoReconnect = true;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onAutoReconnect = () => brokerStatus.value = BrokerStatus.connecting;
    _client.onAutoReconnected = _onConnected;

    final connMsg = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .startClean()
        .withWillTopic('${AppConfig.topicOnline}-app')
        .withWillMessage('offline')
        .withWillQos(MqttQos.atLeastOnce)
        .withWillRetain();
    _client.connectionMessage = connMsg;
  }

  final _clientId =
      'flutter-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';

  late final MqttClient _client = createMqttClient(_clientId);

  final brokerStatus = ValueNotifier<BrokerStatus>(BrokerStatus.disconnected);
  final deviceOnline = ValueNotifier<bool>(false);
  final ledState = ValueNotifier<LedState>(const LedState.initial());
  final sensor = ValueNotifier<SensorReading?>(null);

  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _sub;

  Future<void> connect() async {
    if (brokerStatus.value != BrokerStatus.disconnected) return;
    brokerStatus.value = BrokerStatus.connecting;
    try {
      await _client.connect();
    } catch (e) {
      debugPrint('[MQTT] connect failed: $e');
      _client.disconnect();
      brokerStatus.value = BrokerStatus.disconnected;
    }
  }

  void disconnect() {
    _sub?.cancel();
    _sub = null;
    _client.disconnect();
    brokerStatus.value = BrokerStatus.disconnected;
    deviceOnline.value = false;
  }

  void _onConnected() {
    brokerStatus.value = BrokerStatus.connected;
    _client.subscribe(AppConfig.topicState, MqttQos.atLeastOnce);
    _client.subscribe(AppConfig.topicSensor, MqttQos.atLeastOnce);
    _client.subscribe(AppConfig.topicOnline, MqttQos.atLeastOnce);

    _sub ??= _client.updates!.listen(_onMessages);
  }

  void _onDisconnected() {
    brokerStatus.value = BrokerStatus.disconnected;
    deviceOnline.value = false;
  }

  void _onMessages(List<MqttReceivedMessage<MqttMessage>> events) {
    for (final e in events) {
      final payload = MqttPublishPayload.bytesToStringAsString(
        (e.payload as MqttPublishMessage).payload.message,
      );
      final topic = e.topic;

      if (topic == AppConfig.topicState) {
        final s = LedState.tryParse(payload);
        if (s != null) ledState.value = s;
      } else if (topic == AppConfig.topicSensor) {
        final s = SensorReading.tryParse(payload);
        if (s != null) sensor.value = s;
      } else if (topic == AppConfig.topicOnline) {
        deviceOnline.value = payload == 'online';
      }
    }
  }

  // ---------- commands ----------

  void _publish(Map<String, dynamic> partial) {
    if (brokerStatus.value != BrokerStatus.connected) return;
    final builder = MqttClientPayloadBuilder()..addString(jsonEncode(partial));
    _client.publishMessage(
      AppConfig.topicCmd,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  void setPower(bool on) => _publish({'power': on});
  void setBrightness(int value) =>
      _publish({'brightness': value.clamp(0, 255)});
  void setColor(int r, int g, int b) => _publish({'r': r, 'g': g, 'b': b});

  void dispose() {
    _sub?.cancel();
    _client.disconnect();
    brokerStatus.dispose();
    deviceOnline.dispose();
    ledState.dispose();
    sensor.dispose();
  }
}
