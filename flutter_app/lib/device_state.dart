import 'dart:convert';
import 'dart:ui' show Color;

/// Snapshot of what the ESP32 currently drives onto the LED.
class LedState {
  final bool power;
  final int brightness;
  final int r;
  final int g;
  final int b;

  const LedState({
    required this.power,
    required this.brightness,
    required this.r,
    required this.g,
    required this.b,
  });

  const LedState.initial()
      : power = false,
        brightness = 255,
        r = 255,
        g = 255,
        b = 255;

  Color get color => Color.fromARGB(255, r, g, b);

  LedState copyWith({bool? power, int? brightness, int? r, int? g, int? b}) {
    return LedState(
      power: power ?? this.power,
      brightness: brightness ?? this.brightness,
      r: r ?? this.r,
      g: g ?? this.g,
      b: b ?? this.b,
    );
  }

  static LedState? tryParse(String payload) {
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return LedState(
        power: map['power'] as bool? ?? false,
        brightness: (map['brightness'] as num?)?.toInt() ?? 255,
        r: (map['r'] as num?)?.toInt() ?? 255,
        g: (map['g'] as num?)?.toInt() ?? 255,
        b: (map['b'] as num?)?.toInt() ?? 255,
      );
    } catch (_) {
      return null;
    }
  }
}

class SensorReading {
  final double temperature;
  final double humidity;

  const SensorReading({required this.temperature, required this.humidity});

  static SensorReading? tryParse(String payload) {
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return SensorReading(
        temperature: (map['temperature'] as num).toDouble(),
        humidity: (map['humidity'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
