#pragma once

// ============================================================
//  User Configuration
// ============================================================
//  Adjust WiFi credentials and the device id, then flash.
//  The device id is part of the MQTT topics and must match
//  the value configured in the Flutter app.
// ============================================================

#define WIFI_SSID       "YOUR_WIFI_SSID"
#define WIFI_PASSWORD   "YOUR_WIFI_PASSWORD"

// HiveMQ public broker (no authentication)
#define MQTT_HOST       "broker.hivemq.com"
#define MQTT_PORT       1883

// Unique namespace – change this to anything unique for you,
// so your messages do not collide with other students.
#define DEVICE_ID       "htl-cca-volker-esp32"

// ---------------- Hardware pins (ESP32 DevKit V1) ----------------
#define PIN_LED_R       25   // PWM red
#define PIN_LED_G       26   // PWM green
#define PIN_LED_B       27   // PWM blue
#define PIN_BUTTON       4   // tactile switch to GND (INPUT_PULLUP)
#define PIN_DHT         15   // DHT22 data pin

// Set to 1 if your RGB LED is common-anode (inverted PWM),
// 0 for common-cathode. Single colour LEDs should use 0.
#define LED_COMMON_ANODE 0

// Sensor update interval (ms)
#define SENSOR_INTERVAL_MS  5000
