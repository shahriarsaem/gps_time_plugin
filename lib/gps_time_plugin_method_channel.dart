import 'package:flutter/services.dart';

import 'gps_time_plugin_platform_interface.dart';

/// An implementation of [GpsTimePluginPlatform] that uses method channels.
class MethodChannelGpsTimePlugin extends GpsTimePluginPlatform {
  /// The method channel used to invoke native commands.
  final _methodChannel = const MethodChannel('gps_time_plugin');

  /// The event channel used to receive streaming GPS time updates.
  final _eventChannel = const EventChannel('gps_time_plugin/events');

  @override
  Stream<Map<dynamic, dynamic>> get gpsTimeStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => event as Map<dynamic, dynamic>);
  }

  @override
  Future<void> startListening() async {
    await _methodChannel.invokeMethod<void>('startListening');
  }

  @override
  Future<void> stopListening() async {
    await _methodChannel.invokeMethod<void>('stopListening');
  }
}
