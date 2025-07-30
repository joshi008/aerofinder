import Foundation
import UserNotifications
import CoreLocation

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var notificationPermissionGranted = false
    @Published var notificationHistory: [FlightNotification] = []
    
    private let userNotificationCenter = UNUserNotificationCenter.current()
    private var lastNotificationTime: Date?
    private let minimumNotificationInterval: TimeInterval = 300 // 5 minutes between notifications
    
    override init() {
        super.init()
        userNotificationCenter.delegate = self
        checkNotificationPermission()
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermission() {
        userNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.notificationPermissionGranted = granted
                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func checkNotificationPermission() {
        userNotificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Flight Notifications
    
    func sendFlightNotification(for flight: Flight, distance: Double) {
        guard notificationPermissionGranted else {
            print("Notification permission not granted")
            return
        }
        
        // Rate limiting - don't spam notifications
        if let lastTime = lastNotificationTime,
           Date().timeIntervalSince(lastTime) < minimumNotificationInterval {
            return
        }
        
        let notification = createFlightNotification(for: flight, distance: distance)
        
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        content.badge = 1
        
        // Add custom user info for handling notification taps
        content.userInfo = [
            "flightId": flight.id,
            "callsign": flight.callsign ?? "",
            "distance": distance,
            "notificationType": "flight_detection"
        ]
        
        // Create trigger for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "flight_\(flight.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        userNotificationCenter.add(request) { [weak self] error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self?.lastNotificationTime = Date()
                    self?.notificationHistory.append(notification)
                    print("Flight notification sent: \(notification.title)")
                }
            }
        }
    }
    
    private func createFlightNotification(for flight: Flight, distance: Double) -> FlightNotification {
        let callsign = flight.displayName
        let distanceString = formatDistance(distance)
        let aircraftType = flight.aircraftInfo?.displayName ?? "Unknown Aircraft"
        
        let title = "✈️ \(callsign) Flying Overhead"
        
        var body = "\(aircraftType) is passing \(distanceString) away"
        
        // Add altitude if available
        if let altitude = flight.altitude {
            let altitudeFt = Int(altitude * 3.28084)
            body += " at \(altitudeFt) ft"
        }
        
        // Add an interesting fact if available
        if let fact = flight.aircraftInfo?.randomFact {
            body += "\n\n💡 \(fact.description)"
        }
        
        return FlightNotification(
            id: UUID().uuidString,
            title: title,
            body: body,
            flightId: flight.id,
            callsign: callsign,
            distance: distance,
            timestamp: Date()
        )
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance)) meters"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    // MARK: - Notification History
    
    func clearNotificationHistory() {
        notificationHistory.removeAll()
    }
    
    func getRecentNotifications(limit: Int = 10) -> [FlightNotification] {
        return Array(notificationHistory.suffix(limit).reversed())
    }
    
    // MARK: - Background Notifications
    
    func sendBackgroundFlightNotification(for flight: Flight, distance: Double) {
        // For background notifications, use a simpler format
        let content = UNMutableNotificationContent()
        content.title = "Flight Detected"
        content.body = "\(flight.displayName) is flying \(formatDistance(distance)) away"
        content.sound = .default
        
        content.userInfo = [
            "flightId": flight.id,
            "callsign": flight.callsign ?? "",
            "distance": distance,
            "notificationType": "background_flight_detection"
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "bg_flight_\(flight.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        userNotificationCenter.add(request) { error in
            if let error = error {
                print("Failed to send background notification: \(error.localizedDescription)")
            } else {
                print("Background flight notification sent")
            }
        }
    }
    
    // MARK: - Test Notifications
    
    func sendTestNotification() {
        guard notificationPermissionGranted else {
            requestNotificationPermission()
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "AeroFinder Test"
        content.body = "Flight detection is working! You'll be notified when aircraft fly overhead."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test_notification_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        userNotificationCenter.add(request) { error in
            if let error = error {
                print("Failed to send test notification: \(error.localizedDescription)")
            } else {
                print("Test notification sent")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notifications even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let flightId = userInfo["flightId"] as? String {
            handleFlightNotificationTap(flightId: flightId, userInfo: userInfo)
        }
        
        completionHandler()
    }
    
    private func handleFlightNotificationTap(flightId: String, userInfo: [AnyHashable: Any]) {
        // Post notification for the app to handle (e.g., open flight details)
        NotificationCenter.default.post(
            name: NSNotification.Name("FlightNotificationTapped"),
            object: nil,
            userInfo: userInfo
        )
        
        print("User tapped notification for flight: \(flightId)")
    }
}

// MARK: - Flight Notification Model

struct FlightNotification: Identifiable, Codable {
    let id: String
    let title: String
    let body: String
    let flightId: String
    let callsign: String
    let distance: Double
    let timestamp: Date
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
} 