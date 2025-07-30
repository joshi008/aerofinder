import UIKit
import CoreLocation

class FlightListViewController: UIViewController {
    
    // MARK: - Properties
    
    var flights: [Flight] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.updateEmptyState()
            }
        }
    }
    
    var userLocation: CLLocation?
    
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
        title = "Nearby Flights"
        view.backgroundColor = UIColor.systemBackground
        
        // Navigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshTapped)
        )
    }
    
    private func setupTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(FlightTableViewCell.self, forCellReuseIdentifier: "FlightCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        
        view.addSubview(tableView)
        
        // Empty state label
        emptyStateLabel = UILabel()
        emptyStateLabel.text = "No flights detected nearby"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.textColor = UIColor.secondaryLabel
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
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
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func updateEmptyState() {
        let isEmpty = flights.isEmpty
        emptyStateLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func refreshTapped() {
        FlightService.shared.refreshFlights()
    }
}

// MARK: - UITableViewDataSource

extension FlightListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return flights.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FlightCell", for: indexPath) as! FlightTableViewCell
        let flight = flights[indexPath.row]
        cell.configure(with: flight, userLocation: userLocation)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension FlightListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let flight = flights[indexPath.row]
        let detailVC = FlightDetailViewController()
        detailVC.flight = flight
        detailVC.userLocation = userLocation
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - FlightTableViewCell

class FlightTableViewCell: UITableViewCell {
    
    private let callsignLabel = UILabel()
    private let aircraftLabel = UILabel()
    private let altitudeLabel = UILabel()
    private let velocityLabel = UILabel()
    private let distanceLabel = UILabel()
    private let directionLabel = UILabel()
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
        callsignLabel.font = UIFont.boldSystemFont(ofSize: 16)
        aircraftLabel.font = UIFont.systemFont(ofSize: 14)
        aircraftLabel.textColor = UIColor.secondaryLabel
        altitudeLabel.font = UIFont.systemFont(ofSize: 12)
        altitudeLabel.textColor = UIColor.secondaryLabel
        velocityLabel.font = UIFont.systemFont(ofSize: 12)
        velocityLabel.textColor = UIColor.secondaryLabel
        distanceLabel.font = UIFont.boldSystemFont(ofSize: 14)
        distanceLabel.textColor = UIColor.systemBlue
        directionLabel.font = UIFont.systemFont(ofSize: 12)
        directionLabel.textColor = UIColor.secondaryLabel
        
        // Configure airplane icon
        airplaneIcon.image = UIImage(systemName: "airplane")
        airplaneIcon.tintColor = UIColor.systemBlue
        airplaneIcon.contentMode = .scaleAspectFit
        
        // Set translatesAutoresizingMaskIntoConstraints
        [callsignLabel, aircraftLabel, altitudeLabel, velocityLabel, distanceLabel, directionLabel, airplaneIcon].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        // Constraints
        NSLayoutConstraint.activate([
            // Airplane icon
            airplaneIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            airplaneIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            airplaneIcon.widthAnchor.constraint(equalToConstant: 24),
            airplaneIcon.heightAnchor.constraint(equalToConstant: 24),
            
            // Callsign label
            callsignLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            callsignLabel.leadingAnchor.constraint(equalTo: airplaneIcon.trailingAnchor, constant: 12),
            
            // Aircraft label
            aircraftLabel.topAnchor.constraint(equalTo: callsignLabel.bottomAnchor, constant: 2),
            aircraftLabel.leadingAnchor.constraint(equalTo: callsignLabel.leadingAnchor),
            
            // Altitude and velocity labels
            altitudeLabel.topAnchor.constraint(equalTo: aircraftLabel.bottomAnchor, constant: 4),
            altitudeLabel.leadingAnchor.constraint(equalTo: callsignLabel.leadingAnchor),
            altitudeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            velocityLabel.topAnchor.constraint(equalTo: altitudeLabel.topAnchor),
            velocityLabel.leadingAnchor.constraint(equalTo: altitudeLabel.trailingAnchor, constant: 16),
            
            directionLabel.topAnchor.constraint(equalTo: velocityLabel.topAnchor),
            directionLabel.leadingAnchor.constraint(equalTo: velocityLabel.trailingAnchor, constant: 16),
            
            // Distance label
            distanceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            distanceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            distanceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: callsignLabel.trailingAnchor, constant: 8)
        ])
    }
    
    func configure(with flight: Flight, userLocation: CLLocation?) {
        callsignLabel.text = flight.displayName
        aircraftLabel.text = flight.aircraftInfo?.displayName ?? "Unknown Aircraft"
        altitudeLabel.text = "Alt: \(flight.altitudeString)"
        velocityLabel.text = "Speed: \(flight.velocityString)"
        directionLabel.text = "Hdg: \(flight.headingString)"
        
        if let userLocation = userLocation {
            distanceLabel.text = flight.distanceStringFrom(location: userLocation)
        } else {
            distanceLabel.text = "Unknown"
        }
        
        // Rotate airplane icon based on heading
        if let heading = flight.heading {
            let radians = heading * .pi / 180
            airplaneIcon.transform = CGAffineTransform(rotationAngle: radians)
        } else {
            airplaneIcon.transform = .identity
        }
    }
} 