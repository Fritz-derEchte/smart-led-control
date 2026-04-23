// ============================================================
//  Smart LED Control (IoT) – ESP32 Firmware
//  Project: HTL Anichstraße – UC Smart LED Control
//
//  Features
//   - Remote on/off, brightness and RGB colour over MQTT
//   - Physical push button toggles power (debounced)
//   - Retained state topic – app shows current state on launch
//   - Online/offline (Last-Will) for connection indicator
//   - Optional DHT22 sensor data (temperature / humidity)
// ============================================================

#include <Arduino.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <DHT.h>

#include "config.h"

// ---------------- MQTT topics ----------------
static const String TOPIC_BASE   = String("htl/smartled/") + DEVICE_ID;
static const String TOPIC_CMD    = TOPIC_BASE + "/cmd";
static const String TOPIC_STATE  = TOPIC_BASE + "/state";
static const String TOPIC_SENSOR = TOPIC_BASE + "/sensor";
static const String TOPIC_ONLINE = TOPIC_BASE + "/online";

// ---------------- PWM setup ----------------
static const int PWM_FREQ        = 5000;
static const int PWM_RES_BITS    = 8;        // 0-255
static const int CH_R = 0, CH_G = 1, CH_B = 2;

// ---------------- State ----------------
struct LedState {
    bool     power      = false;
    uint8_t  brightness = 255;    // 0-255
    uint8_t  r          = 255;
    uint8_t  g          = 255;
    uint8_t  b          = 255;
};
static LedState state;

WiFiClient   wifiClient;
PubSubClient mqtt(wifiClient);
DHT          dht(PIN_DHT, DHT22);

static unsigned long lastSensorPublish = 0;
static unsigned long lastButtonChange  = 0;
static int           lastButtonReading = HIGH;
static int           stableButtonState = HIGH;

// ---------------- Helpers ----------------
static inline uint8_t scale(uint8_t value, uint8_t brightness) {
    return (uint16_t)value * brightness / 255;
}

static void applyLed() {
    uint8_t r = 0, g = 0, b = 0;
    if (state.power) {
        r = scale(state.r, state.brightness);
        g = scale(state.g, state.brightness);
        b = scale(state.b, state.brightness);
    }
#if LED_COMMON_ANODE
    ledcWrite(CH_R, 255 - r);
    ledcWrite(CH_G, 255 - g);
    ledcWrite(CH_B, 255 - b);
#else
    ledcWrite(CH_R, r);
    ledcWrite(CH_G, g);
    ledcWrite(CH_B, b);
#endif
}

static void publishState() {
    JsonDocument doc;
    doc["power"]      = state.power;
    doc["brightness"] = state.brightness;
    doc["r"]          = state.r;
    doc["g"]          = state.g;
    doc["b"]          = state.b;

    char buf[128];
    size_t n = serializeJson(doc, buf, sizeof(buf));
    mqtt.publish(TOPIC_STATE.c_str(), (const uint8_t*)buf, n, true); // retained
    Serial.printf("[MQTT] state -> %s\n", buf);
}

static void handleCommand(const String& payload) {
    JsonDocument doc;
    DeserializationError err = deserializeJson(doc, payload);
    if (err) {
        Serial.printf("[MQTT] bad json: %s\n", err.c_str());
        return;
    }

    bool changed = false;
    if (doc["power"].is<bool>())       { state.power      = doc["power"];       changed = true; }
    if (doc["brightness"].is<int>())   { state.brightness = constrain((int)doc["brightness"], 0, 255); changed = true; }
    if (doc["r"].is<int>())            { state.r          = constrain((int)doc["r"], 0, 255); changed = true; }
    if (doc["g"].is<int>())            { state.g          = constrain((int)doc["g"], 0, 255); changed = true; }
    if (doc["b"].is<int>())            { state.b          = constrain((int)doc["b"], 0, 255); changed = true; }

    if (changed) {
        applyLed();
        publishState();
    }
}

static void mqttCallback(char* topic, byte* payload, unsigned int length) {
    String msg;
    msg.reserve(length);
    for (unsigned int i = 0; i < length; ++i) msg += (char)payload[i];
    Serial.printf("[MQTT] %s <- %s\n", topic, msg.c_str());

    if (String(topic) == TOPIC_CMD) handleCommand(msg);
}

static void connectWifi() {
    Serial.printf("[WiFi] connecting to %s ", WIFI_SSID);
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    while (WiFi.status() != WL_CONNECTED) {
        delay(300);
        Serial.print('.');
    }
    Serial.printf("\n[WiFi] ok, ip=%s\n", WiFi.localIP().toString().c_str());
}

static void connectMqtt() {
    while (!mqtt.connected()) {
        String clientId = String(DEVICE_ID) + "-" + String((uint32_t)ESP.getEfuseMac(), HEX);
        Serial.printf("[MQTT] connecting as %s ... ", clientId.c_str());

        // Last-Will: mark device offline if it disconnects unexpectedly
        bool ok = mqtt.connect(
            clientId.c_str(),
            nullptr, nullptr,
            TOPIC_ONLINE.c_str(), 1, true, "offline"
        );

        if (ok) {
            Serial.println("ok");
            mqtt.publish(TOPIC_ONLINE.c_str(), "online", true);
            mqtt.subscribe(TOPIC_CMD.c_str(), 1);
            publishState();
        } else {
            Serial.printf("failed rc=%d, retrying in 2s\n", mqtt.state());
            delay(2000);
        }
    }
}

static void publishSensor() {
    float t = dht.readTemperature();
    float h = dht.readHumidity();
    if (isnan(t) || isnan(h)) return;   // no sensor attached / read error

    JsonDocument doc;
    doc["temperature"] = t;
    doc["humidity"]    = h;

    char buf[96];
    size_t n = serializeJson(doc, buf, sizeof(buf));
    mqtt.publish(TOPIC_SENSOR.c_str(), (const uint8_t*)buf, n, true); // retained
    Serial.printf("[MQTT] sensor -> %s\n", buf);
}

static void pollButton() {
    int reading = digitalRead(PIN_BUTTON);
    unsigned long now = millis();

    if (reading != lastButtonReading) {
        lastButtonChange = now;
        lastButtonReading = reading;
    }

    // 40 ms software debounce
    if (now - lastButtonChange > 40 && reading != stableButtonState) {
        stableButtonState = reading;
        if (stableButtonState == LOW) {     // pressed (INPUT_PULLUP)
            state.power = !state.power;
            applyLed();
            if (mqtt.connected()) publishState();
            Serial.printf("[BTN] toggle -> %s\n", state.power ? "ON" : "OFF");
        }
    }
}

// ============================================================
void setup() {
    Serial.begin(115200);
    delay(200);
    Serial.println("\n[BOOT] Smart LED Control");

    pinMode(PIN_BUTTON, INPUT_PULLUP);

    ledcSetup(CH_R, PWM_FREQ, PWM_RES_BITS); ledcAttachPin(PIN_LED_R, CH_R);
    ledcSetup(CH_G, PWM_FREQ, PWM_RES_BITS); ledcAttachPin(PIN_LED_G, CH_G);
    ledcSetup(CH_B, PWM_FREQ, PWM_RES_BITS); ledcAttachPin(PIN_LED_B, CH_B);
    applyLed();

    dht.begin();

    connectWifi();

    mqtt.setServer(MQTT_HOST, MQTT_PORT);
    mqtt.setBufferSize(512);
    mqtt.setCallback(mqttCallback);
}

void loop() {
    if (WiFi.status() != WL_CONNECTED) connectWifi();
    if (!mqtt.connected())             connectMqtt();
    mqtt.loop();

    pollButton();

    unsigned long now = millis();
    if (now - lastSensorPublish > SENSOR_INTERVAL_MS) {
        lastSensorPublish = now;
        publishSensor();
    }
}
