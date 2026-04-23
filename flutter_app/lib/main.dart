import 'package:flutter/material.dart';

import 'mqtt_service.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SmartLedApp());
}

class SmartLedApp extends StatefulWidget {
  const SmartLedApp({super.key});

  @override
  State<SmartLedApp> createState() => _SmartLedAppState();
}

class _SmartLedAppState extends State<SmartLedApp> {
  final _service = MqttService();

  @override
  void initState() {
    super.initState();
    _service.connect();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart LED Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(service: _service),
    );
  }
}
