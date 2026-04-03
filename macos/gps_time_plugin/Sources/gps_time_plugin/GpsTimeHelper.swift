import CoreLocation
import Foundation

/// GPS time helper for macOS using CoreLocation.
///
/// macOS CoreLocation provides location fixes with timestamps.
/// The timestamp reflects the system clock at fix time — functionally
/// equivalent to the iOS implementation.
class GpsTimeHelper: NSObject {

    // MARK: - Properties

    private let locationManager = CLLocationManager()

    /// Callback invoked whenever a new time update is available.
    var onTimeUpdate: (([String: Any]) -> Void)?

    private var locationTimestamp: Int64?
    private var currentAccuracy: Double?
    private var locationAgeSeconds: Int?
    private var statusMessage: String = "Waiting for GPS..."

    // MARK: - Lifecycle

    override init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
    }

    // MARK: - Public API

    func startListening() {
        let status: CLAuthorizationStatus
        if #available(macOS 11.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            statusMessage = "Requesting location permission..."
            sendUpdate()
        case .denied, .restricted:
            statusMessage = "Location permission denied. Please enable in System Settings."
            sendUpdate()
        case .authorizedAlways, .authorized:
            statusMessage = "Starting GPS..."
            sendUpdate()
            locationManager.startUpdatingLocation()
        @unknown default:
            statusMessage = "Unknown authorization status"
            sendUpdate()
        }
    }

    func stopListening() {
        locationManager.stopUpdatingLocation()
        statusMessage = "GPS stopped"
        sendUpdate()
    }

    // MARK: - Private helpers

    private func updateTimeFromLocation(_ location: CLLocation, isLastKnown: Bool = false) {
        let accuracy = location.horizontalAccuracy
        currentAccuracy = accuracy

        let timestamp = location.timestamp
        let epochMillis = Int64(timestamp.timeIntervalSince1970 * 1000)
        locationTimestamp = epochMillis

        let ageSeconds = Int(Date().timeIntervalSince(timestamp))
        locationAgeSeconds = ageSeconds

        let statusPrefix = isLastKnown ? "Cached" : "Fresh"
        statusMessage = "\(statusPrefix) GPS fix (\(ageSeconds)s old, accuracy: \(Int(accuracy))m)"
        sendUpdate()
    }

    private func sendUpdate() {
        var data: [String: Any] = ["statusMessage": statusMessage]

        if let timestamp = locationTimestamp {
            data["trustedTime"] = timestamp
        }
        data["deviceTime"] = Int64(Date().timeIntervalSince1970 * 1000)

        if let age = locationAgeSeconds {
            data["ageSeconds"] = age
        }
        if let accuracy = currentAccuracy {
            data["accuracy"] = accuracy
        }

        onTimeUpdate?(data)
    }
}

// MARK: - CLLocationManagerDelegate

extension GpsTimeHelper: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        updateTimeFromLocation(location, isLastKnown: false)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                statusMessage = "Location permission denied"
            case .locationUnknown:
                statusMessage = "Location unknown. Searching for GPS signal..."
            default:
                statusMessage = "Error: \(error.localizedDescription)"
            }
        } else {
            statusMessage = "Error: \(error.localizedDescription)"
        }
        sendUpdate()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status: CLAuthorizationStatus
        if #available(macOS 11.0, *) {
            status = manager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        switch status {
        case .authorizedAlways, .authorized:
            statusMessage = "Permission granted. Starting GPS..."
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            statusMessage = "Location permission denied"
        case .notDetermined:
            statusMessage = "Waiting for permission..."
        @unknown default:
            statusMessage = "Unknown authorization status"
        }
        sendUpdate()
    }
}
