//
//  AppDelegate.swift
//  AeroFinder
//
//  Created by Hrishabh Joshi on 30/07/25.
//

import UIKit
import BackgroundTasks
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Register background task
        registerBackgroundTasks()
        
        // Request notification permissions
        requestNotificationPermissions()
        
        // Start location tracking
        LocationService.shared.requestLocationPermissions()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    // MARK: Background Tasks
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.aerofinder.app.background-flight-check", using: nil) { task in
            self.handleBackgroundFlightCheck(task: task as! BGAppRefreshTask)
        }
    }
    
    private func handleBackgroundFlightCheck(task: BGAppRefreshTask) {
        // Schedule the next background task
        BackgroundTaskManager.shared.scheduleBackgroundFlightCheck()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform flight check
        BackgroundTaskManager.shared.performBackgroundFlightCheck { success in
            task.setTaskCompleted(success: success)
        }
    }
    
    // MARK: Notifications
    
    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        BackgroundTaskManager.shared.scheduleBackgroundFlightCheck()
    }
}

