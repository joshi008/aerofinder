//
//  ViewController.swift
//  AeroFinder
//
//  Created by Hrishabh Joshi on 30/07/25.
//

import UIKit

class ViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupAppearance()
    }
    
    private func setupTabBar() {
        // Create Flight Map View Controller
        let flightMapVC = FlightMapViewController()
        let mapNavController = UINavigationController(rootViewController: flightMapVC)
        mapNavController.tabBarItem = UITabBarItem(
            title: "Flights",
            image: UIImage(systemName: "airplane"),
            selectedImage: UIImage(systemName: "airplane.fill")
        )
        
        // Create Settings View Controller
        let settingsVC = SettingsViewController()
        let settingsNavController = UINavigationController(rootViewController: settingsVC)
        settingsNavController.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gear"),
            selectedImage: UIImage(systemName: "gear.fill")
        )
        
        // Set view controllers
        viewControllers = [mapNavController, settingsNavController]
        
        // Set default selection
        selectedIndex = 0
    }
    
    private func setupAppearance() {
        // Configure tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        
        // Set tint colors
        tabBar.tintColor = UIColor.systemBlue
        tabBar.unselectedItemTintColor = UIColor.systemGray
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Initialize services when the main view appears
        initializeAppServices()
    }
    
    private func initializeAppServices() {
        // Start location services
        LocationService.shared.requestLocationPermissions()
        
        // Request notification permissions
        NotificationService.shared.requestNotificationPermission()
        
        // Set up notification observers
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFlightNotificationTap),
            name: NSNotification.Name("FlightNotificationTapped"),
            object: nil
        )
    }
    
    @objc private func handleFlightNotificationTap(_ notification: Notification) {
        // Switch to flights tab when user taps a flight notification
        selectedIndex = 0
        
        // Pass the flight information to the map view controller
        if let mapNavController = viewControllers?[0] as? UINavigationController,
           let flightMapVC = mapNavController.topViewController as? FlightMapViewController {
            flightMapVC.handleFlightNotificationTap(notification)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

