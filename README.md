# gps_time_plugin

[![pub package](https://img.shields.io/pub/v/gps_time_plugin.svg)](https://pub.dev/packages/gps_time_plugin)

A Flutter plugin that provides **accurate GPS-synced time** on Android and iOS. It extracts trusted time from GPS location fixes, making it suitable for applications where device system clock manipulation or drift is a concern — such as attendance tracking, event logging, or secure timestamping.

---

## Platform Support

| Platform | Support |
|----------|---------|
| Android  | ✅ API 24+ |
| iOS      | ✅ iOS 13+ |

---

## How It Works

### Android
Uses `android.location.LocationManager` to receive GPS/Network location fixes. Each fix includes `elapsedRealtimeNanos` — the number of nanoseconds since boot when the fix was made. By combining this with the fix's UTC timestamp and the current `SystemClock.elapsedRealtimeNanos()`, the plugin calculates an accurate, adjusted trusted time that accounts for the age of the fix.

### iOS
Uses `CoreLocation` (`CLLocationManager`) to receive location updates. Each `CLLocation` has a `.timestamp` representing the device system clock at the moment of the fix. **Note:** iOS does not expose raw GPS atomic clock time — the time provided on iOS is the system clock captured at the moment a GPS fix is received, which is still more reliable than `DateTime.now()` in tamper scenarios.

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  gps_time_plugin: ^0.0.1
```

---

## Required Permissions

### Android

Add to your app's `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

You **must** request location permissions at runtime before calling `startListening()`. Use a package like [`permission_handler`](https://pub.dev/packages/permission_handler).

### iOS

Add to your app's `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app uses your location to provide accurate GPS-synced time.</string>
```

---

## Usage

```dart
import 'package:gps_time_plugin/gps_time_plugin.dart';

final _plugin = GpsTimePlugin();

// Request permissions first (use permission_handler or similar)

// Start listening
await _plugin.startListening();

// Listen to GPS time stream
_plugin.gpsTimeStream.listen((GpsTimeState state) {
  print('Status: ${state.statusMessage}');
  
  if (state.trustedTime != null) {
    print('GPS Time: ${state.trustedTime}');
    print('Accuracy: ${state.accuracy}m');
    print('Fix age: ${state.ageSeconds}s');
  }
});

// Stop when done
await _plugin.stopListening();
```

### GpsTimeState Fields

| Field | Type | Description |
|-------|------|-------------|
| `trustedTime` | `DateTime?` | GPS-adjusted UTC time, null until first fix |
| `epochMillis` | `int?` | Trusted time as epoch milliseconds |
| `accuracy` | `double?` | GPS horizontal accuracy in meters |
| `ageSeconds` | `int?` | Age of the GPS fix in seconds |
| `deviceTime` | `DateTime?` | Device system clock at time of update |
| `statusMessage` | `String` | Human-readable status for UI display |

---

## Limitations

- **Cold GPS start** can take 30–90 seconds to get the first fix without a SIM card or WiFi.
- **iOS** does not expose raw GPS atomic time. The timestamp is from the device system clock at the moment a GPS fix is received.
- The plugin requires the caller to handle location permissions before calling `startListening()`.
- Background location updates are **not enabled** by default. Configure your app accordingly if needed.

---

## License

MIT — see [LICENSE](LICENSE)
