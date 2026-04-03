import 'package:flutter_test/flutter_test.dart';
import 'package:gps_time_plugin/gps_time_plugin.dart';

void main() {
  test('GpsTimeState default statusMessage', () {
    const state = GpsTimeState();
    expect(state.statusMessage, 'Initializing...');
    expect(state.trustedTime, isNull);
    expect(state.accuracy, isNull);
  });

  test('GpsTimeState.fromMap parses trustedTime correctly', () {
    final map = <dynamic, dynamic>{
      'trustedTime': 1700000000000,
      'accuracy': 5.5,
      'ageSeconds': 2,
      'deviceTime': 1700000000050,
      'statusMessage': 'Fresh GPS fix (2s old, accuracy: 5m)',
    };

    final state = GpsTimeState.fromMap(map);

    expect(state.epochMillis, 1700000000000);
    expect(state.trustedTime, isNotNull);
    expect(state.accuracy, 5.5);
    expect(state.ageSeconds, 2);
    expect(state.deviceTime, isNotNull);
    expect(state.statusMessage, 'Fresh GPS fix (2s old, accuracy: 5m)');
  });

  test('GpsTimeState equality', () {
    const a = GpsTimeState(epochMillis: 1000, statusMessage: 'test');
    const b = GpsTimeState(epochMillis: 1000, statusMessage: 'test');
    expect(a, equals(b));
  });

  test('GpsTimeState copyWith', () {
    const original = GpsTimeState(statusMessage: 'original');
    final copied = original.copyWith(statusMessage: 'updated');
    expect(copied.statusMessage, 'updated');
    expect(copied.trustedTime, original.trustedTime);
  });
}
