import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../device_state.dart';
import '../mqtt_service.dart';

class ControlTab extends StatelessWidget {
  const ControlTab({super.key, required this.service});

  final MqttService service;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LedState>(
      valueListenable: service.ledState,
      builder: (context, state, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PreviewBulb(state: state),
              const SizedBox(height: 24),
              _PowerCard(state: state, service: service),
              const SizedBox(height: 16),
              _BrightnessCard(state: state, service: service),
              const SizedBox(height: 16),
              _ColorCard(state: state, service: service),
            ],
          ),
        );
      },
    );
  }
}

class _PreviewBulb extends StatelessWidget {
  const _PreviewBulb({required this.state});
  final LedState state;

  @override
  Widget build(BuildContext context) {
    final color = state.power
        ? Color.fromARGB(
            255,
            (state.r * state.brightness / 255).round(),
            (state.g * state.brightness / 255).round(),
            (state.b * state.brightness / 255).round(),
          )
        : Colors.grey.shade800;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: state.power
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.7),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                ]
              : [],
        ),
        child: Icon(
          state.power ? Icons.lightbulb : Icons.lightbulb_outline,
          size: 72,
          color: Colors.white.withOpacity(0.85),
        ),
      ),
    );
  }
}

class _PowerCard extends StatelessWidget {
  const _PowerCard({required this.state, required this.service});
  final LedState state;
  final MqttService service;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: const Text('Power'),
        subtitle: Text(state.power ? 'Eingeschaltet' : 'Ausgeschaltet'),
        value: state.power,
        onChanged: service.setPower,
        secondary: Icon(
          state.power ? Icons.power : Icons.power_off,
          color: state.power ? Colors.amber : null,
        ),
      ),
    );
  }
}

class _BrightnessCard extends StatefulWidget {
  const _BrightnessCard({required this.state, required this.service});
  final LedState state;
  final MqttService service;

  @override
  State<_BrightnessCard> createState() => _BrightnessCardState();
}

class _BrightnessCardState extends State<_BrightnessCard> {
  double? _dragValue;
  Timer? _throttle;

  void _onChanged(double v) {
    setState(() => _dragValue = v);
    _throttle?.cancel();
    _throttle = Timer(const Duration(milliseconds: 60), () {
      widget.service.setBrightness(v.round());
    });
  }

  void _onChangeEnd(double v) {
    _throttle?.cancel();
    widget.service.setBrightness(v.round());
    setState(() => _dragValue = null);
  }

  @override
  void dispose() {
    _throttle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _dragValue ?? widget.state.brightness.toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.brightness_6),
                const SizedBox(width: 8),
                const Text('Helligkeit'),
                const Spacer(),
                Text('${value.round()}'),
              ],
            ),
            Slider(
              value: value,
              min: 0,
              max: 255,
              divisions: 255,
              onChanged: _onChanged,
              onChangeEnd: _onChangeEnd,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorCard extends StatelessWidget {
  const _ColorCard({required this.state, required this.service});
  final LedState state;
  final MqttService service;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette),
                const SizedBox(width: 8),
                const Text('Farbe'),
                const Spacer(),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: state.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets
                  .map(
                    (c) => _Swatch(
                      color: c,
                      selected: state.color.value == c.value,
                      onTap: () => service.setColor(c.red, c.green, c.blue),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.colorize),
                label: const Text('Eigene Farbe…'),
                onPressed: () => _openPicker(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    Color tmp = state.color;
    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Farbe wählen'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: state.color,
            enableAlpha: false,
            labelTypes: const [],
            onColorChanged: (c) => tmp = c,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, tmp), child: const Text('Übernehmen')),
        ],
      ),
    );
    if (picked != null) {
      service.setColor(picked.red, picked.green, picked.blue);
    }
  }

  static const _presets = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFFFD27A), // warm white
    Color(0xFFFF2D2D),
    Color(0xFF29D26B),
    Color(0xFF2E84FF),
    Color(0xFFFFC400),
    Color(0xFFB14BFF),
    Color(0xFF19E0D8),
  ];
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected, required this.onTap});
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.white24,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
