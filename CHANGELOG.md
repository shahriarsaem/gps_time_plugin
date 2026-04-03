## 0.0.2

- **Android**: Fix tamper-resistant time calculation using `elapsedRealtimeNanos` boot-epoch offset — trusted time is now immune to manual system clock changes.
- **Android**: Fix reversed fix-age validation logic; correct package namespace to `com.shahriarsaem.gpstimeplugin`.
- **iOS**: Fix double `setupGpsCallback()` registration that caused early GPS events to be dropped.
- **iOS**: Replace deprecated `CLLocationManager.authorizationStatus()` static call with instance property.
- **macOS**: Add full macOS platform support via CoreLocation.
- **SPM**: Add Swift Package Manager support for iOS and macOS (`Package.swift`).
- **Dart**: Fix stream subscription order in example app — subscribe before `startListening()` to avoid missing initial status events.
- **Dart**: Add 1-second live timer in example app so Clock Drift tile updates instantly after manual clock changes.
- **pubspec**: Shorten description to comply with pub.dev 60–180 character limit.

## 0.0.1

* Initial release.
* Android: Extracts GPS-synced time from `LocationManager` using `elapsedRealtimeNanos` offset calculation for high accuracy.
* Android: Emits trusted time, GPS accuracy, and status messages via an `EventChannel` stream.
* iOS: Extracts location timestamp from `CLLocationManager` and streams it via an `EventChannel`.
* Dart: Exposes `GpsTimeState` model with `trustedTime`, `accuracy`, `ageSeconds`, `deviceTime`, and `statusMessage`.
* Supports `startListening()` and `stopListening()` lifecycle methods.
