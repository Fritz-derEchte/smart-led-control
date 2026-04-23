import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'app_config.dart';

MqttClient createMqttClient(String clientId) =>
    MqttServerClient.withPort(AppConfig.mqttHost, clientId, AppConfig.mqttPort);
