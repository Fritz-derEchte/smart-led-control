# Smart LED Control (IoT)

Fernsteuerung einer (RGB-)LED an einem **ESP32** über eine **Flutter-App**.
Kommunikation läuft in Echtzeit über den öffentlichen **HiveMQ MQTT-Broker**.
Projekt für **HTL Anichstraße – CCA (UC Smart LED Control)**.

---

## Inhalt

| Ordner | Inhalt |
| --- | --- |
| [`esp32/`](esp32) | PlatformIO-Firmware für den ESP32 (Arduino-Framework) |
| [`flutter_app/`](flutter_app) | Flutter-App (Android/iOS/Desktop) |

---

## Umgesetzte Aufgaben

| # | Aufgabe | Status |
| - | ------- | ------ |
| 1 | Remote Control ON/OFF, physischer Taster, Status-Feedback, Verbindungsanzeige | ✅ |
| 2 | Dimmen über Slider (0-255) mit Status-Feedback | ✅ |
| 3 | RGB-Steuerung mit Color-Picker + Farb-Presets inkl. Status-Feedback | ✅ |
| 4 | Sensor-Dashboard (DHT22 → Temperatur & Luftfeuchtigkeit) – *optional* | ✅ |

Alle Zustände (`power`, `brightness`, `r`, `g`, `b`) werden zentral vom ESP32 gehalten.
Jede Änderung – egal ob über App oder Taster – wird **retained** auf das State-Topic
gepublisht; die App zeigt deshalb nach dem Start sofort den korrekten Zustand an.

---

## Architektur

```
 ┌──────────────┐    MQTT (TCP 1883)     ┌──────────────────┐
 │ Flutter-App  │ ─────────────────────► │  HiveMQ Broker   │
 │ (Android/iOS)│ ◄───────────────────── │ broker.hivemq.com│
 └──────────────┘                        └─────────▲────────┘
                                                   │
                                                   │
                                          ┌────────┴────────┐
                                          │     ESP32       │
                                          │  RGB-LED + BTN  │
                                          │   + DHT22       │
                                          └─────────────────┘
```

### MQTT-Topics

Basis: `htl/smartled/<DEVICE_ID>` (Default: `htl-cca-volker-esp32`)

| Topic | Richtung | Retain | Payload |
| ----- | -------- | ------ | ------- |
| `…/cmd`    | App → ESP32 | nein | Partial JSON: `{"power":true,"brightness":200,"r":0,"g":255,"b":128}` |
| `…/state`  | ESP32 → App | **ja** | Vollständiger Zustand als JSON |
| `…/sensor` | ESP32 → App | ja | `{"temperature":22.4,"humidity":41.0}` |
| `…/online` | ESP32 → App | ja | `online` bzw. `offline` (Last-Will) |

Die App subscribed `…/state`, `…/sensor`, `…/online`.
Nur der ESP32 publishet auf `…/state` – die App ist konsequent nur Konsument
des „Wahrheitszustands“.

---

## Hardware

ESP32 DevKit V1 o. ä., gängige Wiring:

| ESP32-Pin | Funktion        | Bauteil                            |
| --------- | --------------- | ---------------------------------- |
| GPIO 25   | PWM rot         | R-Anschluss RGB-LED (+ 220 Ω)      |
| GPIO 26   | PWM grün        | G-Anschluss RGB-LED (+ 220 Ω)      |
| GPIO 27   | PWM blau        | B-Anschluss RGB-LED (+ 220 Ω)      |
| GND/3V3   | LED gemeinsam   | Common-Cathode an GND (Default)    |
| GPIO 4    | Taster (INPUT_PULLUP) | Taster zwischen GPIO 4 und GND |
| GPIO 15   | DHT22 Data      | DHT22 + 10 kΩ Pull-Up auf 3V3      |

> Bei **Common-Anode-LED**: `LED_COMMON_ANODE` in `esp32/src/config.h` auf `1` setzen.
> Für eine einfache weiße LED genügt ein Kanal – dann bleibt die Farbsteuerung ohne
> Wirkung, Power + Brightness funktionieren trotzdem.

---

## Setup

### 1. ESP32 (PlatformIO)

```bash
cd esp32
cp src/config.example.h src/config.h   # einmalig – config.h ist gitignored
# WiFi-Zugangsdaten und optional DEVICE_ID in src/config.h eintragen
pio run -t upload      # flashen
pio device monitor     # serieller Output
```

Benötigte Libraries werden von PlatformIO automatisch installiert
(`PubSubClient`, `ArduinoJson`, `DHT sensor library`).

### 2. Flutter-App

```bash
cd flutter_app
flutter create .       # generiert Plattform-Ordner (android/ios/…)
flutter pub get
flutter run
```

> **Android:** In `android/app/src/main/AndroidManifest.xml` sicherstellen, dass
> `<uses-permission android:name="android.permission.INTERNET" />` gesetzt ist
> (`flutter create` erzeugt das per Default).
>
> **macOS/Desktop:** Netzwerk-Entitlement aktivieren
> (`com.apple.security.network.client`).

`DEVICE_ID` in `flutter_app/lib/app_config.dart` muss mit dem Wert in
`esp32/src/config.h` übereinstimmen.

---

## Bedienung

- **Power-Schalter** in der App → sofortige Reaktion am ESP32.
- **Physischer Taster** → LED togglet, App aktualisiert sich in <200 ms.
- **Slider** dimmt linear 0-255 (PWM).
- **Color-Picker** → beliebige RGB-Farbe wählen; 8 Presets als Shortcut.
- **Sensor-Tab** zeigt aktuelle Temperatur/Luftfeuchtigkeit vom DHT22.
- **Verbindungs-Chip** oben rechts:
  - grün = Broker verbunden + ESP32 online
  - orange = Broker ok, aber ESP32 meldet `offline`
  - rot = kein Broker

---

## Git-Workflow

Das Projekt folgt dem auf Moodle publizierten *Git-Workflow-Standard*:

- `main` ist immer deploybar.
- Pro Aufgabe / Feature ein **Feature-Branch** (`feat/aufgabe-X-…`).
- Aussagekräftige, kleine Commits im *Conventional-Commits*-Stil
  (`feat:`, `fix:`, `docs:`, `chore:` …).
- Merge via Pull Request in `main`.
