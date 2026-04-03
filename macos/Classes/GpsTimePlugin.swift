import FlutterMacOS
import Foundation

public class GpsTimePlugin: NSObject, FlutterPlugin {

    private var gpsTimeHelper: GpsTimeHelper?
    private var eventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "gps_time_plugin",
            binaryMessenger: registrar.messenger
        )
        let eventChannel = FlutterEventChannel(
            name: "gps_time_plugin/events",
            binaryMessenger: registrar.messenger
        )

        let instance = GpsTimePlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startListening":
            if gpsTimeHelper == nil {
                gpsTimeHelper = GpsTimeHelper()
            }
            gpsTimeHelper?.startListening()
            result(nil)

        case "stopListening":
            gpsTimeHelper?.stopListening()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func setupGpsCallback() {
        gpsTimeHelper?.onTimeUpdate = { [weak self] data in
            self?.eventSink?(data)
        }
    }
}

// MARK: - FlutterStreamHandler

extension GpsTimePlugin: FlutterStreamHandler {

    public func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        self.eventSink = events
        if gpsTimeHelper == nil {
            gpsTimeHelper = GpsTimeHelper()
        }
        setupGpsCallback()
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        gpsTimeHelper?.onTimeUpdate = nil
        return nil
    }
}
