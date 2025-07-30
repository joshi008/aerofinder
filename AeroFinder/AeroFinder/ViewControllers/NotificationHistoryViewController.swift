import UIKit

class NotificationHistoryViewController: UIViewController {
    
    // MARK: - Properties
    
    var notifications: [FlightNotification] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.updateEmptyState()
            }
        }
    }
    
    // MARK: - UI Elements
    
    private var tableView: UITableView!
    private var emptyStateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        updateEmptyState()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        title = "Notification History"
        view.backgroundColor = UIColor.systemBackground
        
        // Navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Clear All",
            style: .plain,
            target: self,
            action: #selector(clearAllTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = UIColor.systemRed
    }
    
    private func setupTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(NotificationTableViewCell.self, forCellReuseIdentifier: "NotificationCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.separatorStyle = .singleLine
        
        view.addSubview(tableView)
        
        // Empty state label
        emptyStateLabel = UILabel()
        emptyStateLabel.text = "No notification history\nYou'll see flight notifications here when they arrive."
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.textColor = UIColor.secondaryLabel
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.isHidden = true
        
        view.addSubview(emptyStateLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    private func updateEmptyState() {
        let isEmpty = notifications.isEmpty
        emptyStateLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        navigationItem.rightBarButtonItem?.isEnabled = !isEmpty
    }
    
    // MARK: - Actions
    
    @objc private func clearAllTapped() {
        let alert = UIAlertController(
            title: "Clear All Notifications",
            message: "Are you sure you want to clear all notification history? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Clear All", style: .destructive) { _ in
            NotificationService.shared.clearNotificationHistory()
            self.notifications = []
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension NotificationHistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as! NotificationTableViewCell
        let notification = notifications[indexPath.row]
        cell.configure(with: notification)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension NotificationHistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let notification = notifications[indexPath.row]
        showNotificationDetail(notification)
    }
    
    private func showNotificationDetail(_ notification: FlightNotification) {
        let alert = UIAlertController(
            title: notification.title,
            message: notification.body,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
}

// MARK: - NotificationTableViewCell

class NotificationTableViewCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let timeLabel = UILabel()
    private let callsignLabel = UILabel()
    private let distanceLabel = UILabel()
    private let airplaneIcon = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Configure labels
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.numberOfLines = 2
        
        bodyLabel.font = UIFont.systemFont(ofSize: 14)
        bodyLabel.textColor = UIColor.secondaryLabel
        bodyLabel.numberOfLines = 3
        
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = UIColor.tertiaryLabel
        
        callsignLabel.font = UIFont.systemFont(ofSize: 12)
        callsignLabel.textColor = UIColor.systemBlue
        
        distanceLabel.font = UIFont.systemFont(ofSize: 12)
        distanceLabel.textColor = UIColor.secondaryLabel
        
        // Configure airplane icon
        airplaneIcon.image = UIImage(systemName: "airplane.fill")
        airplaneIcon.tintColor = UIColor.systemBlue
        airplaneIcon.contentMode = .scaleAspectFit
        
        // Set translatesAutoresizingMaskIntoConstraints
        [titleLabel, bodyLabel, timeLabel, callsignLabel, distanceLabel, airplaneIcon].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        // Constraints
        NSLayoutConstraint.activate([
            // Airplane icon
            airplaneIcon.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            airplaneIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            airplaneIcon.widthAnchor.constraint(equalToConstant: 20),
            airplaneIcon.heightAnchor.constraint(equalToConstant: 20),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: airplaneIcon.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            
            // Time label
            timeLabel.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            // Body label
            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Callsign label
            callsignLabel.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 8),
            callsignLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            callsignLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            // Distance label
            distanceLabel.topAnchor.constraint(equalTo: callsignLabel.topAnchor),
            distanceLabel.leadingAnchor.constraint(equalTo: callsignLabel.trailingAnchor, constant: 16),
            distanceLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(with notification: FlightNotification) {
        titleLabel.text = notification.title
        bodyLabel.text = notification.body
        timeLabel.text = notification.timeAgo
        callsignLabel.text = notification.callsign
        
        let distanceString: String
        if notification.distance < 1000 {
            distanceString = "\(Int(notification.distance))m away"
        } else {
            distanceString = String(format: "%.1fkm away", notification.distance / 1000)
        }
        distanceLabel.text = distanceString
    }
} 