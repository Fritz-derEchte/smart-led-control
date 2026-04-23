import 'package:flutter/material.dart';

import '../device_state.dart';
import '../mqtt_service.dart';

class SensorTab extends StatelessWidget {
  const SensorTab({super.key, required this.service});

  final MqttService service;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SensorReading?>(
      valueListenable: service.sensor,
      builder: (context, reading, _) {
        if (reading == null) {
          return const _Empty();
        }
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: _SensorCard(
                  icon: Icons.thermostat,
                  color: Colors.redAccent,
                  label: 'Temperatur',
                  value: '${reading.temperature.toStringAsFixed(1)} °C',
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _SensorCard(
                  icon: Icons.water_drop,
                  color: Colors.blueAccent,
                  label: 'Luftfeuchtigkeit',
                  value: '${reading.humidity.toStringAsFixed(1)} %',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sensors_off, size: 64),
            SizedBox(height: 12),
            Text(
              'Noch keine Sensordaten empfangen.\n'
              'DHT22 am ESP32 anschließen oder Broker-Verbindung prüfen.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
