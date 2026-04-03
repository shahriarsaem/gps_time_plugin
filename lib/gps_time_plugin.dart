import 'gps_time_plugin_platform_interface.dart';

/// Represents a single GPS time update event from the native platform.
class GpsTimeState {
  /// GPS-adjusted UTC time. `null` until the first location fix is received.
  final DateTime? trustedTime;

  /// [trustedTime] expressed as milliseconds since Unix epoch. `null` until the
  /// first location fix is received.
  final int? epochMillis;

  /// Horizontal accuracy of the GPS fix in meters. Lower is better.
  final double? accuracy;

  /// Age of the GPS fix in seconds at the moment the event was sent.
  final int? ageSeconds;

  /// Device system clock at the moment the native side sent this event.
  /// Useful for computing clock drift relative to [trustedTime].
  final DateTime? deviceTime;

  /// Human-readable status message suitable for display in a UI.
  final String statusMessage;

  const GpsTimeState({
    this.trustedTime,
    this.epochMillis,
    this.accuracy,
    this.ageSeconds,
    this.deviceTime,
    this.statusMessage = 'Initializing...',
  });

  factory GpsTimeState.fromMap(Map<dynamic, dynamic> map) {
    final epochMs = map['trustedTime'] as int?;
    final deviceEpochMs = map['deviceTime'] as int?;

    return GpsTimeState(
      trustedTime: epochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true)
          : null,
      epochMillis: epochMs,
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      ageSeconds: (map['ageSeconds'] as num?)?.toInt(),
      deviceTime: deviceEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(deviceEpochMs, isUtc: true)
          : null,
      statusMessage: map['statusMessage'] as String? ?? 'Unknown',
    );
  }

  /// Returns a copy of this [GpsTimeState] with the given fields replaced.
  GpsTimeState copyWith({
    DateTime? trustedTime,
    int? epochMillis,
    double? accuracy,
    int? ageSeconds,
    DateTime? deviceTime,
    String? statusMessage,
  }) {
    return GpsTimeState(
      trustedTime: trustedTime ?? this.trustedTime,
      epochMillis: epochMillis ?? this.epochMillis,
      accuracy: accuracy ?? this.accuracy,
      ageSeconds: ageSeconds ?? this.ageSeconds,
      deviceTime: deviceTime ?? this.deviceTime,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GpsTimeState &&
          runtimeType == other.runtimeType &&
          epochMillis == other.epochMillis &&
          accuracy == other.accuracy &&
          ageSeconds == other.ageSeconds &&
          statusMessage == other.statusMessage;

  @override
  int get hashCode =>
      epochMillis.hashCode ^
      accuracy.hashCode ^
      ageSeconds.hashCode ^
      statusMessage.hashCode;

  @override
  String toString() {
    return 'GpsTimeState('
        'trustedTime: $trustedTime, '
        'accuracy: ${accuracy?.toStringAsFixed(1)}m, '
        'ageSeconds: $ageSeconds, '
        'status: $statusMessage'
        ')';
  }
}

/// Main plugin class. Use this to start/stop GPS listening and subscribe to
/// the [gpsTimeStream].
///
/// **Permissions required before calling [startListening]:**
/// - Android: `ACCESS_FINE_LOCATION`
/// - iOS: `NSLocationWhenInUseUsageDescription` in Info.plist
class GpsTimePlugin {
  /// Starts listening for GPS location updates.
  ///
  /// Ensure you have requested and received location permissions before calling
  /// this. Consider using the `permission_handler` package.
  Future<void> startListening() {
    return GpsTimePluginPlatform.instance.startListening();
  }

  /// Stops listening for GPS location updates and releases resources.
  Future<void> stopListening() {
    return GpsTimePluginPlatform.instance.stopListening();
  }

  /// Stream of GPS time states.
  ///
  /// Emits a new [GpsTimeState] whenever a location update is received.
  /// Subscribe after calling [startListening].
  Stream<GpsTimeState> get gpsTimeStream {
    return GpsTimePluginPlatform.instance.gpsTimeStream
        .map((event) => GpsTimeState.fromMap(event));
  }
}
