import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'gps_time_plugin_method_channel.dart';

abstract class GpsTimePluginPlatform extends PlatformInterface {
  /// Constructs a GpsTimePluginPlatform.
  GpsTimePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static GpsTimePluginPlatform _instance = MethodChannelGpsTimePlugin();

  /// The default instance of [GpsTimePluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelGpsTimePlugin].
  static GpsTimePluginPlatform get instance => _instance;

  static set instance(GpsTimePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Stream of raw GPS time data maps from the native platform.
  Stream<Map<dynamic, dynamic>> get gpsTimeStream {
    throw UnimplementedError('gpsTimeStream has not been implemented.');
  }

  /// Starts GPS location updates on the native side.
  Future<void> startListening() {
    throw UnimplementedError('startListening() has not been implemented.');
  }

  /// Stops GPS location updates on the native side.
  Future<void> stopListening() {
    throw UnimplementedError('stopListening() has not been implemented.');
  }
}
