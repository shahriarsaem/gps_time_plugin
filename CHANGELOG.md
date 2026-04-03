## 0.0.1

* Initial release.
* Android: Extracts GPS-synced time from `LocationManager` using `elapsedRealtimeNanos` offset calculation for high accuracy.
* Android: Emits trusted time, GPS accuracy, and status messages via an `EventChannel` stream.
* iOS: Extracts location timestamp from `CLLocationManager` and streams it via an `EventChannel`.
* Dart: Exposes `GpsTimeState` model with `trustedTime`, `accuracy`, `ageSeconds`, `deviceTime`, and `statusMessage`.
* Supports `startListening()` and `stopListening()` lifecycle methods.
