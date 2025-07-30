import UIKit
import MapKit
import CoreLocation
import Combine

class FlightMapViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private var mapView: MKMapView!
    private var refreshButton: UIBarButtonItem!
    private var locationButton: UIBarButtonItem!
    private var loadingIndicator: UIActivityIndicatorView!
    private var statusLabel: UILabel!
    private var flightListButton: UIButton!
    
    // MARK: - Properties
    
    private let locationService = LocationService.shared
    private let flightService = FlightService.shared
    private var flightAnnotations: [FlightAnnotation] = []
    private var userLocationAnnotation: MKPointAnnotation?
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMapView()
        setupServices()
        setupConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startLocationTracking()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        title = "AeroFinder"
        view.backgroundColor = UIColor.systemBackground
        
        // Create map view programmatically
        mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        
        // Setup navigation bar
        setupNavigationBar()
        
        // Setup status elements
        setupStatusElements()
        
        // Setup flight list button
        setupFlightListButton()
    }
    
    private func setupNavigationBar() {
        // Refresh button
        refreshButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshFlights)
        )
        
        // Location button
        locationButton = UIBarButtonItem(
            image: UIImage(systemName: "location"),
            style: .plain,
            target: self,
            action: #selector(centerOnUserLocation)
        )
        
        navigationItem.rightBarButtonItems = [refreshButton, locationButton]
        
        // Loading indicator for navigation bar
        loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.hidesWhenStopped = true
    }
    
    private func setupStatusElements() {
        statusLabel = UILabel()
        statusLabel.text = "Searching for flights..."
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textColor = UIColor.secondaryLabel
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
    }
    
    private func setupFlightListButton() {
        flightListButton = UIButton(type: .system)
        flightListButton.setTitle("Show Flight List", for: .normal)
        flightListButton.backgroundColor = UIColor.systemBlue
        flightListButton.setTitleColor(.white, for: .normal)
        flightListButton.layer.cornerRadius = 8
        flightListButton.translatesAutoresizingMaskIntoConstraints = false
        flightListButton.addTarget(self, action: #selector(showFlightList), for: .touchUpInside)
        view.addSubview(flightListButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Map view constraints
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Status label constraints
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            statusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            statusLabel.heightAnchor.constraint(equalToConstant: 20),
            
            // Flight list button constraints
            flightListButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            flightListButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            flightListButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            flightListButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - MapView Setup
    
    private func setupMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.mapType = .standard
        
        // Set initial region to a reasonable zoom level
        let initialRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco as default
            latitudinalMeters: 50000,
            longitudinalMeters: 50000
        )
        mapView.setRegion(initialRegion, animated: false)
    }
    
    // MARK: - Services Setup
    
    private func setupServices() {
        locationService.delegate = self
        flightService.delegate = self
        
        // Observe flight service loading state
        flightService.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateLoadingState(isLoading)
            }
            .store(in: &cancellables)
        
        // Observe nearby flights
        flightService.$nearbyFlights
            .receive(on: DispatchQueue.main)
            .sink { [weak self] flights in
                self?.updateFlightAnnotations(flights)
                self?.updateStatusLabel(flightCount: flights.count)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Location Tracking
    
    private func startLocationTracking() {
        locationService.startRealTimeTracking()
    }
    
    // MARK: - Flight Annotations
    
    private func updateFlightAnnotations(_ flights: [Flight]) {
        // Remove existing flight annotations
        mapView.removeAnnotations(flightAnnotations)
        flightAnnotations.removeAll()
        
        // Add new flight annotations
        for flight in flights {
            guard let coordinate = flight.coordinate else { continue }
            
            let annotation = FlightAnnotation(flight: flight)
            annotation.coordinate = coordinate
            annotation.title = flight.displayName
            annotation.subtitle = "\(flight.altitudeString) • \(flight.velocityString)"
            
            flightAnnotations.append(annotation)
            mapView.addAnnotation(annotation)
        }
        
        print("Updated map with \(flights.count) flight annotations")
    }
    
    private func updateStatusLabel(flightCount: Int) {
        if flightCount == 0 {
            statusLabel.text = "No flights detected nearby"
        } else {
            statusLabel.text = "\(flightCount) flight\(flightCount == 1 ? "" : "s") detected"
        }
    }
    
    private func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            let loadingButton = UIBarButtonItem(customView: loadingIndicator)
            navigationItem.leftBarButtonItem = loadingButton
            loadingIndicator.startAnimating()
        } else {
            navigationItem.leftBarButtonItem = nil
            loadingIndicator.stopAnimating()
        }
        
        refreshButton.isEnabled = !isLoading
    }
    
    // MARK: - Actions
    
    @objc private func refreshFlights() {
        flightService.refreshFlights()
    }
    
    @objc private func centerOnUserLocation() {
        guard let userLocation = locationService.currentLocation else {
            showLocationAlert()
            return
        }
        
        let region = MKCoordinateRegion(
            center: userLocation.coordinate,
            latitudinalMeters: 20000,
            longitudinalMeters: 20000
        )
        mapView.setRegion(region, animated: true)
    }
    
    @objc private func showFlightList() {
        let flightListVC = FlightListViewController()
        flightListVC.flights = flightService.nearbyFlights
        
        let navController = UINavigationController(rootViewController: flightListVC)
        present(navController, animated: true)
    }
    
    private func showLocationAlert() {
        let alert = UIAlertController(
            title: "Location Required",
            message: "Please enable location services to see your position and nearby flights.",
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
    
    // MARK: - Notification Handling
    
    func handleFlightNotificationTap(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let flightId = userInfo["flightId"] as? String else { return }
        
        // Find the flight annotation and focus on it
        if let flightAnnotation = flightAnnotations.first(where: { $0.flight.id == flightId }) {
            mapView.selectAnnotation(flightAnnotation, animated: true)
            
            let region = MKCoordinateRegion(
                center: flightAnnotation.coordinate,
                latitudinalMeters: 10000,
                longitudinalMeters: 10000
            )
            mapView.setRegion(region, animated: true)
        }
    }
}

// MARK: - LocationServiceDelegate

extension FlightMapViewController: LocationServiceDelegate {
    func locationService(_ service: LocationService, didUpdateLocation location: CLLocation) {
        // Update map region if this is the first location update
        if userLocationAnnotation == nil {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 20000,
                longitudinalMeters: 20000
            )
            mapView.setRegion(region, animated: true)
        }
    }
    
    func locationService(_ service: LocationService, didFailWithError error: Error) {
        print("Location service error: \(error.localizedDescription)")
        statusLabel.text = "Location service error"
    }
    
    func locationServiceDidChangeAuthorization(_ service: LocationService) {
        // Handle authorization changes
        print("Location authorization changed")
    }
}

// MARK: - FlightServiceDelegate

extension FlightMapViewController: FlightServiceDelegate {
    func flightService(_ service: FlightService, didUpdateFlights flights: [Flight]) {
        // Flights are automatically updated via Combine publishers
    }
    
    func flightService(_ service: FlightService, didDetectNewFlight flight: Flight) {
        // Highlight new flight on map
        if let annotation = flightAnnotations.first(where: { $0.flight.id == flight.id }) {
            mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    func flightService(_ service: FlightService, didFailWithError error: Error) {
        statusLabel.text = "Flight service error"
        print("Flight service error: \(error.localizedDescription)")
    }
}

// MARK: - MKMapViewDelegate

extension FlightMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil // Use default user location view
        }
        
        guard let flightAnnotation = annotation as? FlightAnnotation else {
            return nil
        }
        
        let identifier = "FlightAnnotation"
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        
        annotationView.annotation = annotation
        annotationView.markerTintColor = UIColor.systemBlue
        annotationView.glyphImage = UIImage(systemName: "airplane")
        annotationView.canShowCallout = true
        
        // Add detail disclosure button
        let detailButton = UIButton(type: .detailDisclosure)
        annotationView.rightCalloutAccessoryView = detailButton
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let flightAnnotation = view.annotation as? FlightAnnotation else { return }
        
        let flightDetailVC = FlightDetailViewController()
        flightDetailVC.flight = flightAnnotation.flight
        flightDetailVC.userLocation = locationService.currentLocation
        
        let navController = UINavigationController(rootViewController: flightDetailVC)
        present(navController, animated: true)
    }
}

// MARK: - Flight Annotation

class FlightAnnotation: NSObject, MKAnnotation {
    let flight: Flight
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(flight: Flight) {
        self.flight = flight
        self.coordinate = flight.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        super.init()
    }
} 