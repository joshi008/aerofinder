import Foundation
import CoreLocation
import UIKit

protocol LocationServiceDelegate: AnyObject {
    func locationService(_ service: LocationService, didUpdateLocation location: CLLocation)
    func locationService(_ service: LocationService, didFailWithError error: Error)
    func locationServiceDidChangeAuthorization(_ service: LocationService)
}

class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    private let notificationRadius: Double = 10000 // 10km radius
    
    weak var delegate: LocationServiceDelegate?
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isRealTimeTrackingActive = false
    @Published var isBackgroundTrackingActive = false
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100 // Update every 100 meters
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Permission Management
    
    func requestLocationPermissions() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            showLocationPermissionAlert()
        case .authorizedWhenInUse:
            // Request always authorization for background functionality
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            startLocationServices()
        @unknown default:
            break
        }
    }
    
    private func showLocationPermissionAlert() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }
            
            let alert = UIAlertController(
                title: "Location Access Required",
                message: "AeroFinder needs location access to detect flights overhead. Please enable location permissions in Settings.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    // MARK: - Location Tracking
    
    func startRealTimeTracking() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermissions()
            return
        }
        
        isRealTimeTrackingActive = true
        isBackgroundTrackingActive = false
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50 // More frequent updates for real-time
        locationManager.startUpdatingLocation()
        
        print("Started real-time location tracking")
    }
    
    func startBackgroundTracking() {
        guard authorizationStatus == .authorizedAlways else {
            print("Background tracking requires 'Always' location permission")
            return
        }
        
        isRealTimeTrackingActive = false
        isBackgroundTrackingActive = true
        
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 500 // Less frequent updates for battery efficiency
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
        
        print("Started background location tracking")
    }
    
    func stopLocationTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        isRealTimeTrackingActive = false
        isBackgroundTrackingActive = false
        
        print("Stopped location tracking")
    }
    
    private func startLocationServices() {
        if UIApplication.shared.applicationState == .active {
            startRealTimeTracking()
        } else {
            startBackgroundTracking()
        }
    }
    
    // MARK: - Utility Methods
    
    func getLocationString() -> String {
        guard let location = currentLocation else { return "Unknown Location" }
        return "Lat: \(String(format: "%.4f", location.coordinate.latitude)), Lon: \(String(format: "%.4f", location.coordinate.longitude))"
    }
    
    func isLocationWithinNotificationRadius(from location: CLLocation) -> Bool {
        guard let currentLocation = currentLocation else { return false }
        let distance = currentLocation.distance(from: location)
        return distance <= notificationRadius
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out old or inaccurate locations
        guard location.timestamp.timeIntervalSinceNow > -30,
              location.horizontalAccuracy < 100 else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
        }
        
        delegate?.locationService(self, didUpdateLocation: location)
        
        // Trigger flight check for new location
        FlightService.shared.checkFlightsNearLocation(location)
        
        print("Location updated: \(getLocationString())")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        delegate?.locationService(self, didFailWithError: error)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
        
        delegate?.locationServiceDidChangeAuthorization(self)
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            print("Location permission: When In Use")
            // Request always authorization for background functionality
            manager.requestAlwaysAuthorization()
        case .authorizedAlways:
            print("Location permission: Always")
            startLocationServices()
        case .denied, .restricted:
            print("Location permission denied")
            stopLocationTracking()
        case .notDetermined:
            print("Location permission not determined")
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region: \(region.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
    }
} 