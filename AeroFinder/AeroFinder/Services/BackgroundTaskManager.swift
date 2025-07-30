import Foundation
import BackgroundTasks
import CoreLocation

class BackgroundTaskManager: ObservableObject {
    static let shared = BackgroundTaskManager()
    
    private let backgroundTaskIdentifier = "com.aerofinder.app.background-flight-check"
    
    @Published var lastBackgroundCheck: Date?
    @Published var backgroundCheckCount = 0
    
    private init() {}
    
    // MARK: - Background Task Scheduling
    
    func scheduleBackgroundFlightCheck() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background flight check scheduled for 1 hour from now")
        } catch {
            print("Failed to schedule background task: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Background Task Execution
    
    func performBackgroundFlightCheck(completion: @escaping (Bool) -> Void) {
        guard let currentLocation = getCurrentLocationForBackgroundCheck() else {
            print("No location available for background flight check")
            completion(false)
            return
        }
        
        print("Performing background flight check at \(currentLocation)")
        
        DispatchQueue.main.async {
            self.lastBackgroundCheck = Date()
            self.backgroundCheckCount += 1
        }
        
        // Perform flight check with a shorter timeout for background execution
        FlightService.shared.performBackgroundFlightCheck(at: currentLocation) { success in
            if success {
                print("Background flight check completed successfully")
            } else {
                print("Background flight check failed")
            }
            completion(success)
        }
    }
    
    private func getCurrentLocationForBackgroundCheck() -> CLLocation? {
        // In background, we need to rely on the last known location
        // or request a quick location update if possible
        if let lastLocation = LocationService.shared.currentLocation {
            // Check if location is recent enough (within last 30 minutes)
            if lastLocation.timestamp.timeIntervalSinceNow > -1800 {
                return lastLocation
            }
        }
        
        // Could attempt to get a quick location update here if needed
        // For now, return the last known location even if it's older
        return LocationService.shared.currentLocation
    }
    
    // MARK: - Manual Background Check (for testing)
    
    func triggerManualBackgroundCheck() {
        guard let location = LocationService.shared.currentLocation else {
            print("No current location for manual background check")
            return
        }
        
        performBackgroundFlightCheck { success in
            print("Manual background check completed: \(success)")
        }
    }
    
    // MARK: - Background Task Cleanup
    
    func cancelAllBackgroundTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
        print("All background tasks cancelled")
    }
    
    // MARK: - Debug and Monitoring
    
    func getBackgroundTaskStatus() -> String {
        return """
        Background Flight Checks:
        - Last check: \(lastBackgroundCheck?.description ?? "Never")
        - Total checks: \(backgroundCheckCount)
        - Task ID: \(backgroundTaskIdentifier)
        """
    }
}

// MARK: - Location Service Integration

extension BackgroundTaskManager {
    func setupLocationBasedBackgroundUpdates() {
        // This could be used to trigger background tasks based on significant location changes
        // For now, we rely on the periodic 1-hour checks
        print("Location-based background updates configured")
    }
} 