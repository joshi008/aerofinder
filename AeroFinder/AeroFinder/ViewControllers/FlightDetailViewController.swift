import UIKit
import CoreLocation

class FlightDetailViewController: UIViewController {
    
    // MARK: - Properties
    
    var flight: Flight!
    var userLocation: CLLocation?
    
    // MARK: - UI Elements
    
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureWithFlight()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        title = "Flight Details"
        view.backgroundColor = UIColor.systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        
        setupScrollView()
        setupStackView()
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupStackView() {
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Configuration
    
    private func configureWithFlight() {
        // Flight Header
        addFlightHeader()
        
        // Flight Information
        addFlightInformation()
        
        // Aircraft Information
        addAircraftInformation()
        
        // Aircraft Facts
        addAircraftFacts()
        
        // Location Information
        addLocationInformation()
    }
    
    private func addFlightHeader() {
        let headerView = createHeaderView()
        stackView.addArrangedSubview(headerView)
    }
    
    private func createHeaderView() -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        containerView.layer.cornerRadius = 12
        
        let airplaneIcon = UIImageView(image: UIImage(systemName: "airplane.fill"))
        airplaneIcon.tintColor = UIColor.systemBlue
        airplaneIcon.contentMode = .scaleAspectFit
        
        let callsignLabel = UILabel()
        callsignLabel.text = flight.displayName
        callsignLabel.font = UIFont.boldSystemFont(ofSize: 24)
        callsignLabel.textColor = UIColor.label
        
        let aircraftLabel = UILabel()
        aircraftLabel.text = flight.aircraftInfo?.displayName ?? "Unknown Aircraft"
        aircraftLabel.font = UIFont.systemFont(ofSize: 16)
        aircraftLabel.textColor = UIColor.secondaryLabel
        
        [airplaneIcon, callsignLabel, aircraftLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview($0)
        }
        
        // Rotate airplane icon based on heading
        if let heading = flight.heading {
            let radians = heading * .pi / 180
            airplaneIcon.transform = CGAffineTransform(rotationAngle: radians)
        }
        
        NSLayoutConstraint.activate([
            airplaneIcon.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            airplaneIcon.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            airplaneIcon.widthAnchor.constraint(equalToConstant: 40),
            airplaneIcon.heightAnchor.constraint(equalToConstant: 40),
            
            callsignLabel.topAnchor.constraint(equalTo: airplaneIcon.bottomAnchor, constant: 12),
            callsignLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            aircraftLabel.topAnchor.constraint(equalTo: callsignLabel.bottomAnchor, constant: 4),
            aircraftLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            aircraftLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
        
        return containerView
    }
    
    private func addFlightInformation() {
        let sectionView = createSectionView(title: "Flight Information")
        
        var infoItems: [(String, String)] = []
        
        if let altitude = flight.altitude {
            infoItems.append(("Altitude", flight.altitudeString))
        }
        
        if let velocity = flight.velocity {
            infoItems.append(("Speed", flight.velocityString))
        }
        
        if let heading = flight.heading {
            infoItems.append(("Heading", flight.headingString))
        }
        
        if let origin = flight.origin {
            infoItems.append(("Origin Country", origin))
        }
        
        if let userLocation = userLocation {
            let distance = flight.distanceStringFrom(location: userLocation)
            infoItems.append(("Distance from You", distance))
        }
        
        infoItems.append(("Last Updated", RelativeDateTimeFormatter().localizedString(for: flight.lastUpdated, relativeTo: Date())))
        
        addInfoItems(to: sectionView, items: infoItems)
        stackView.addArrangedSubview(sectionView)
    }
    
    private func addAircraftInformation() {
        guard let aircraftInfo = flight.aircraftInfo else { return }
        
        let sectionView = createSectionView(title: "Aircraft Information")
        
        var infoItems: [(String, String)] = []
        
        infoItems.append(("ICAO24", aircraftInfo.icao24))
        
        if let registration = aircraftInfo.registration {
            infoItems.append(("Registration", registration))
        }
        
        if let manufacturer = aircraftInfo.manufacturer {
            infoItems.append(("Manufacturer", manufacturer))
        }
        
        if let model = aircraftInfo.model {
            infoItems.append(("Model", model))
        }
        
        if let specs = aircraftInfo.specs {
            if let maxPassengers = specs.maxPassengers {
                infoItems.append(("Max Passengers", "\(maxPassengers)"))
            }
            
            if let maxSpeed = specs.maxSpeed {
                infoItems.append(("Max Speed", "\(maxSpeed) km/h"))
            }
            
            if let range = specs.range {
                infoItems.append(("Range", "\(range) km"))
            }
            
            if let engines = specs.engines {
                infoItems.append(("Engines", "\(engines)"))
            }
        }
        
        addInfoItems(to: sectionView, items: infoItems)
        stackView.addArrangedSubview(sectionView)
    }
    
    private func addAircraftFacts() {
        guard let aircraftInfo = flight.aircraftInfo, !aircraftInfo.facts.isEmpty else { return }
        
        let sectionView = createSectionView(title: "Interesting Facts")
        
        for fact in aircraftInfo.facts {
            let factView = createFactView(fact: fact)
            sectionView.addArrangedSubview(factView)
        }
        
        stackView.addArrangedSubview(sectionView)
    }
    
    private func addLocationInformation() {
        guard let coordinate = flight.coordinate else { return }
        
        let sectionView = createSectionView(title: "Location")
        
        let infoItems: [(String, String)] = [
            ("Latitude", String(format: "%.6f°", coordinate.latitude)),
            ("Longitude", String(format: "%.6f°", coordinate.longitude))
        ]
        
        addInfoItems(to: sectionView, items: infoItems)
        stackView.addArrangedSubview(sectionView)
    }
    
    // MARK: - Helper Methods
    
    private func createSectionView(title: String) -> UIStackView {
        let sectionStack = UIStackView()
        sectionStack.axis = .vertical
        sectionStack.spacing = 12
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = UIColor.label
        
        sectionStack.addArrangedSubview(titleLabel)
        
        return sectionStack
    }
    
    private func addInfoItems(to sectionView: UIStackView, items: [(String, String)]) {
        for (key, value) in items {
            let infoView = createInfoItemView(key: key, value: value)
            sectionView.addArrangedSubview(infoView)
        }
    }
    
    private func createInfoItemView(key: String, value: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.secondarySystemBackground
        containerView.layer.cornerRadius = 8
        
        let keyLabel = UILabel()
        keyLabel.text = key
        keyLabel.font = UIFont.systemFont(ofSize: 14)
        keyLabel.textColor = UIColor.secondaryLabel
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 16)
        valueLabel.textColor = UIColor.label
        valueLabel.numberOfLines = 0
        
        [keyLabel, valueLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            keyLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            keyLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            keyLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            valueLabel.topAnchor.constraint(equalTo: keyLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            valueLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
        
        return containerView
    }
    
    private func createFactView(fact: AircraftFact) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.1)
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemYellow.withAlphaComponent(0.3).cgColor
        
        let iconLabel = UILabel()
        iconLabel.text = "💡"
        iconLabel.font = UIFont.systemFont(ofSize: 20)
        
        let titleLabel = UILabel()
        titleLabel.text = fact.title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = UIColor.label
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = fact.description
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = UIColor.secondaryLabel
        descriptionLabel.numberOfLines = 0
        
        [iconLabel, titleLabel, descriptionLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            iconLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            iconLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            descriptionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        return containerView
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
} 