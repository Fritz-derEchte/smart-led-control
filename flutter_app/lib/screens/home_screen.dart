import 'package:flutter/material.dart';

import '../mqtt_service.dart';
import 'control_tab.dart';
import 'sensor_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.service});

  final MqttService service;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ControlTab(service: widget.service),
      SensorTab(service: widget.service),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart LED Control'),
        centerTitle: true,
        actions: [
          _ConnectionBadge(service: widget.service),
          const SizedBox(width: 12),
        ],
      ),
      body: tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: 'Steuerung',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors),
            label: 'Sensor',
          ),
        ],
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.service});

  final MqttService service;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BrokerStatus>(
      valueListenable: service.brokerStatus,
      builder: (_, broker, __) {
        return ValueListenableBuilder<bool>(
          valueListenable: service.deviceOnline,
          builder: (_, deviceOnline, __) {
            final (label, color, icon) = _describe(broker, deviceOnline);
            return Tooltip(
              message: label,
              child: Chip(
                avatar: Icon(icon, size: 16, color: Colors.white),
                label: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: color,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            );
          },
        );
      },
    );
  }

  (String, Color, IconData) _describe(BrokerStatus b, bool deviceOnline) {
    switch (b) {
      case BrokerStatus.connected:
        return deviceOnline
            ? ('Verbunden', Colors.green.shade700, Icons.cloud_done)
            : ('Broker ok, ESP offline', Colors.orange.shade700, Icons.cloud_off);
      case BrokerStatus.connecting:
        return ('Verbinde…', Colors.blueGrey, Icons.sync);
      case BrokerStatus.disconnected:
        return ('Getrennt', Colors.red.shade700, Icons.cloud_off);
    }
  }
}
