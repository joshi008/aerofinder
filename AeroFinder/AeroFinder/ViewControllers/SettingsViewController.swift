import UIKit
import CoreLocation

class SettingsViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private var tableView: UITableView!
    
    // MARK: - Properties
    
    private let locationService = LocationService.shared
    private let notificationService = NotificationService.shared
    private let backgroundTaskManager = BackgroundTaskManager.shared
    
    private enum Section: Int, CaseIterable {
        case permissions
        case notifications
        case about
        case debug
        
        var title: String {
            switch self {
            case .permissions: return "Permissions"
            case .notifications: return "Notifications"
            case .about: return "About"
            case .debug: return "Debug"
            }
        }
    }
    
    private enum PermissionRow: Int, CaseIterable {
        case location
        case notification
        
        var title: String {
            switch self {
            case .location: return "Location Access"
            case .notification: return "Push Notifications"
            }
        }
    }
    
    private enum NotificationRow: Int, CaseIterable {
        case testNotification
        case notificationHistory
        case clearHistory
        
        var title: String {
            switch self {
            case .testNotification: return "Send Test Notification"
            case .notificationHistory: return "Notification History"
            case .clearHistory: return "Clear History"
            }
        }
    }
    
    private enum AboutRow: Int, CaseIterable {
        case version
        case privacyPolicy
        case openSource
        
        var title: String {
            switch self {
            case .version: return "Version"
            case .privacyPolicy: return "Privacy Policy"
            case .openSource: return "Open Source Libraries"
            }
        }
    }
    
    private enum DebugRow: Int, CaseIterable {
        case backgroundTasks
        case flightAPIStatus
        case manualFlightCheck
        
        var title: String {
            switch self {
            case .backgroundTasks: return "Background Tasks"
            case .flightAPIStatus: return "Flight API Status"
            case .manualFlightCheck: return "Manual Flight Check"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        title = "Settings"
        view.backgroundColor = UIColor.systemGroupedBackground
        
        setupTableView()
        setupConstraints()
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Register cell types
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BasicCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DetailCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SwitchCell")
        
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupObservers() {
        // Observe location service changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateUI),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func updateUI() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Helper Methods
    
    private func getLocationStatusText() -> String {
        switch locationService.authorizationStatus {
        case .notDetermined:
            return "Not Requested"
        case .denied, .restricted:
            return "Denied"
        case .authorizedWhenInUse:
            return "When In Use"
        case .authorizedAlways:
            return "Always (Recommended)"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func getLocationStatusColor() -> UIColor {
        switch locationService.authorizationStatus {
        case .authorizedAlways:
            return .systemGreen
        case .authorizedWhenInUse:
            return .systemOrange
        case .denied, .restricted:
            return .systemRed
        case .notDetermined:
            return .systemGray
        @unknown default:
            return .systemGray
        }
    }
    
    private func getNotificationStatusText() -> String {
        return notificationService.notificationPermissionGranted ? "Enabled" : "Disabled"
    }
    
    private func getNotificationStatusColor() -> UIColor {
        return notificationService.notificationPermissionGranted ? .systemGreen : .systemRed
    }
    
    private func handleLocationPermissionTap() {
        let alert = UIAlertController(
            title: "Location Permission",
            message: "AeroFinder needs location access to detect flights overhead. For best results, please allow 'Always' access in Settings.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func handleNotificationPermissionTap() {
        if notificationService.notificationPermissionGranted {
            // Already granted, show settings
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        } else {
            // Request permission
            notificationService.requestNotificationPermission()
        }
    }
    
    private func showNotificationHistory() {
        let historyVC = NotificationHistoryViewController()
        historyVC.notifications = notificationService.notificationHistory
        navigationController?.pushViewController(historyVC, animated: true)
    }
    
    private func clearNotificationHistory() {
        let alert = UIAlertController(
            title: "Clear History",
            message: "Are you sure you want to clear all notification history?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            self.notificationService.clearNotificationHistory()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showPrivacyPolicy() {
        let alert = UIAlertController(
            title: "Privacy Policy",
            message: "AeroFinder only uses your location to detect nearby flights. No personal data is collected or shared. Location data is processed locally and never transmitted to third parties except for flight API requests.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
    
    private func showOpenSourceInfo() {
        let alert = UIAlertController(
            title: "Open Source",
            message: "This app uses the free OpenSky Network API for flight data. Special thanks to the OpenSky Network community for providing free access to real-time flight information.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Learn More", style: .default) { _ in
            if let url = URL(string: "https://opensky-network.org") {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showBackgroundTaskStatus() {
        let status = backgroundTaskManager.getBackgroundTaskStatus()
        let alert = UIAlertController(title: "Background Tasks", message: status, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showFlightAPIStatus() {
        let flightService = FlightService.shared
        let status = """
        Flight API Status:
        - Service: OpenSky Network
        - Last Update: \(flightService.lastUpdateTime?.description ?? "Never")
        - Nearby Flights: \(flightService.nearbyFlights.count)
        - Loading: \(flightService.isLoading ? "Yes" : "No")
        """
        
        let alert = UIAlertController(title: "Flight API Status", message: status, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .permissions:
            return PermissionRow.allCases.count
        case .notifications:
            return NotificationRow.allCases.count
        case .about:
            return AboutRow.allCases.count
        case .debug:
            return DebugRow.allCases.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch sectionType {
        case .permissions:
            return configurePermissionCell(tableView, indexPath: indexPath)
        case .notifications:
            return configureNotificationCell(tableView, indexPath: indexPath)
        case .about:
            return configureAboutCell(tableView, indexPath: indexPath)
        case .debug:
            return configureDebugCell(tableView, indexPath: indexPath)
        }
    }
    
    private func configurePermissionCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath)
        cell.textLabel?.text = ""
        cell.detailTextLabel?.text = ""
        
        guard let row = PermissionRow(rawValue: indexPath.row) else { return cell }
        
        cell.textLabel?.text = row.title
        cell.accessoryType = .disclosureIndicator
        
        switch row {
        case .location:
            cell.detailTextLabel?.text = getLocationStatusText()
            cell.detailTextLabel?.textColor = getLocationStatusColor()
        case .notification:
            cell.detailTextLabel?.text = getNotificationStatusText()
            cell.detailTextLabel?.textColor = getNotificationStatusColor()
        }
        
        return cell
    }
    
    private func configureNotificationCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
        
        guard let row = NotificationRow(rawValue: indexPath.row) else { return cell }
        
        cell.textLabel?.text = row.title
        
        switch row {
        case .testNotification:
            cell.accessoryType = .none
            cell.textLabel?.textColor = .systemBlue
        case .notificationHistory:
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = .label
        case .clearHistory:
            cell.accessoryType = .none
            cell.textLabel?.textColor = .systemRed
        }
        
        return cell
    }
    
    private func configureAboutCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        guard let row = AboutRow(rawValue: indexPath.row) else { return UITableViewCell() }
        
        switch row {
        case .version:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath)
            cell.textLabel?.text = row.title
            cell.detailTextLabel?.text = "1.0.0"
            cell.selectionStyle = .none
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
            cell.textLabel?.text = row.title
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    private func configureDebugCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
        
        guard let row = DebugRow(rawValue: indexPath.row) else { return cell }
        
        cell.textLabel?.text = row.title
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.textColor = .systemBlue
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let sectionType = Section(rawValue: indexPath.section) else { return }
        
        switch sectionType {
        case .permissions:
            handlePermissionRowTap(indexPath.row)
        case .notifications:
            handleNotificationRowTap(indexPath.row)
        case .about:
            handleAboutRowTap(indexPath.row)
        case .debug:
            handleDebugRowTap(indexPath.row)
        }
    }
    
    private func handlePermissionRowTap(_ row: Int) {
        guard let permissionRow = PermissionRow(rawValue: row) else { return }
        
        switch permissionRow {
        case .location:
            handleLocationPermissionTap()
        case .notification:
            handleNotificationPermissionTap()
        }
    }
    
    private func handleNotificationRowTap(_ row: Int) {
        guard let notificationRow = NotificationRow(rawValue: row) else { return }
        
        switch notificationRow {
        case .testNotification:
            notificationService.sendTestNotification()
        case .notificationHistory:
            showNotificationHistory()
        case .clearHistory:
            clearNotificationHistory()
        }
    }
    
    private func handleAboutRowTap(_ row: Int) {
        guard let aboutRow = AboutRow(rawValue: row) else { return }
        
        switch aboutRow {
        case .version:
            break // No action for version
        case .privacyPolicy:
            showPrivacyPolicy()
        case .openSource:
            showOpenSourceInfo()
        }
    }
    
    private func handleDebugRowTap(_ row: Int) {
        guard let debugRow = DebugRow(rawValue: row) else { return }
        
        switch debugRow {
        case .backgroundTasks:
            showBackgroundTaskStatus()
        case .flightAPIStatus:
            showFlightAPIStatus()
        case .manualFlightCheck:
            backgroundTaskManager.triggerManualBackgroundCheck()
        }
    }
} 