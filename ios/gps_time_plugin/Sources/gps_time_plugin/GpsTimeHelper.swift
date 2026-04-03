import CoreLocation
import Foundation

/// Helper class to access GPS time using CoreLocation.
///
/// On iOS, CLLocation.timestamp reflects the system clock at the time a GPS fix is
/// received — not a raw GPS satellite atomic clock signal. This still provides a
/// meaningful trusted time anchor tied to a GPS fix event.
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
        locationManager.allowsBackgroundLocationUpdates = false
        // Let iOS auto-pause to conserve battery
        locationManager.pausesLocationUpdatesAutomatically = true
    }

    // MARK: - Public API

    func startListening() {
        let status = currentAuthorizationStatus()

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            statusMessage = "Requesting location permission..."
            sendUpdate()
        case .denied, .restricted:
            statusMessage = "Location permission denied. Please enable in Settings."
            sendUpdate()
        case .authorizedWhenInUse, .authorizedAlways:
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

    private func currentAuthorizationStatus() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }

    private func updateTimeFromLocation(_ location: CLLocation, isLastKnown: Bool = false) {
        let accuracy = location.horizontalAccuracy
        currentAccuracy = accuracy

        let timestamp = location.timestamp
        let epochMillis = Int64(timestamp.timeIntervalSince1970 * 1000)
        locationTimestamp = epochMillis

        let ageSeconds = Int(Date().timeIntervalSince(timestamp))
        locationAgeSeconds = ageSeconds

        let statusPrefix = isLastKnown ? "Cached" : "Fresh"
        let source: String
        if #available(iOS 15.0, *) {
            source = location.sourceInformation?.isProducedByAccessory == true ? "Accessory" : "GPS"
        } else {
            source = "GPS"
        }

        statusMessage = "\(statusPrefix) \(source) fix (\(ageSeconds)s old, accuracy: \(Int(accuracy))m)"
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
            case .network:
                statusMessage = "Network error. Check connectivity."
            default:
                statusMessage = "Error: \(error.localizedDescription)"
            }
        } else {
            statusMessage = "Error: \(error.localizedDescription)"
        }
        sendUpdate()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = currentAuthorizationStatus()

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
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
