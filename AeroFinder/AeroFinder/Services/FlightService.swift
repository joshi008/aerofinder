import Foundation
import CoreLocation

protocol FlightServiceDelegate: AnyObject {
    func flightService(_ service: FlightService, didUpdateFlights flights: [Flight])
    func flightService(_ service: FlightService, didDetectNewFlight flight: Flight)
    func flightService(_ service: FlightService, didFailWithError error: Error)
}

class FlightService: ObservableObject {
    static let shared = FlightService()
    
    weak var delegate: FlightServiceDelegate?
    
    @Published var nearbyFlights: [Flight] = []
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    
    private let openSkyBaseURL = "https://opensky-network.org/api/states/all"
    private let urlSession = URLSession.shared
    private let detectionRadius: Double = 10000 // 10km radius for notifications
    private let updateInterval: TimeInterval = 30 // 30 seconds between updates
    private var lastApiCall: Date?
    private var previousFlightIds = Set<String>()
    
    private init() {}
    
    // MARK: - Flight Detection
    
    func checkFlightsNearLocation(_ location: CLLocation) {
        // Rate limiting - don't call API too frequently
        if let lastCall = lastApiCall,
           Date().timeIntervalSince(lastCall) < updateInterval {
            return
        }
        
        isLoading = true
        lastApiCall = Date()
        
        fetchFlightsFromOpenSky(near: location) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.lastUpdateTime = Date()
                
                switch result {
                case .success(let flights):
                    self?.processNewFlights(flights, userLocation: location)
                case .failure(let error):
                    print("Flight API error: \(error.localizedDescription)")
                    self?.delegate?.flightService(self!, didFailWithError: error)
                }
            }
        }
    }
    
    private func fetchFlightsFromOpenSky(near location: CLLocation, completion: @escaping (Result<[Flight], Error>) -> Void) {
        // Calculate bounding box around location (approximately 20km x 20km)
        let latitudeDelta = 0.18 // roughly 20km at equator
        let longitudeDelta = 0.18
        
        let lamin = location.coordinate.latitude - latitudeDelta
        let lamax = location.coordinate.latitude + latitudeDelta
        let lomin = location.coordinate.longitude - longitudeDelta
        let lomax = location.coordinate.longitude + longitudeDelta
        
        var urlComponents = URLComponents(string: openSkyBaseURL)!
        urlComponents.queryItems = [
            URLQueryItem(name: "lamin", value: String(lamin)),
            URLQueryItem(name: "lamax", value: String(lamax)),
            URLQueryItem(name: "lomin", value: String(lomin)),
            URLQueryItem(name: "lomax", value: String(lomax))
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(FlightServiceError.invalidURL))
            return
        }
        
        print("Fetching flights from: \(url.absoluteString)")
        
        urlSession.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(FlightServiceError.noData))
                return
            }
            
            do {
                let openSkyResponse = try JSONDecoder().decode(OpenSkyResponse.self, from: data)
                let flights = FlightService.parseFlights(from: openSkyResponse, userLocation: location, detectionRadius: self.detectionRadius)
                completion(.success(flights))
            } catch {
                print("JSON parsing error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    private static func parseFlights(from response: OpenSkyResponse, userLocation: CLLocation, detectionRadius: Double) -> [Flight] {
        guard let states = response.states else { return [] }
        
        var flights: [Flight] = []
        
        for state in states {
            // Skip flights that are on ground
            if state.count > 8, let onGround = state[8].intValue, onGround == 1 {
                continue
            }
            
            let flight = Flight(from: state)
            
            // Only include flights that have valid coordinates and are within our detection area
            if let flightLocation = flight.location,
               flightLocation.distance(from: userLocation) <= detectionRadius * 2 { // Wider net for processing
                flights.append(flight)
            }
        }
        
        return flights.sortedByDistance(from: userLocation)
    }
    
    private func processNewFlights(_ flights: [Flight], userLocation: CLLocation) {
        // Update nearby flights
        nearbyFlights = flights
        delegate?.flightService(self, didUpdateFlights: flights)
        
        // Check for new flights that just entered our detection radius
        let currentFlightIds = Set(flights.map { $0.id })
        let newFlightIds = currentFlightIds.subtracting(previousFlightIds)
        
        for flight in flights where newFlightIds.contains(flight.id) {
            // Check if this flight is within notification radius
            if let distance = flight.distanceFrom(location: userLocation),
               distance <= detectionRadius {
                delegate?.flightService(self, didDetectNewFlight: flight)
                
                // Send notification for new nearby flight
                NotificationService.shared.sendFlightNotification(for: flight, distance: distance)
            }
        }
        
        previousFlightIds = currentFlightIds
        
        print("Found \(flights.count) flights nearby, \(newFlightIds.count) are new")
    }
    
    // MARK: - Manual Flight Search
    
    func searchFlightsAtLocation(_ location: CLLocation, completion: @escaping ([Flight]) -> Void) {
        fetchFlightsFromOpenSky(near: location) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let flights):
                    completion(flights)
                case .failure:
                    completion([])
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func getFlightsWithinRadius(_ radius: Double, of location: CLLocation) -> [Flight] {
        return nearbyFlights.within(radius: radius, of: location)
    }
    
    func getNearestFlight(to location: CLLocation) -> Flight? {
        return nearbyFlights.nearestTo(location: location)
    }
    
    func refreshFlights() {
        guard let currentLocation = LocationService.shared.currentLocation else {
            print("No current location available for flight refresh")
            return
        }
        
        checkFlightsNearLocation(currentLocation)
    }
    
    // MARK: - Background Flight Check
    
    func performBackgroundFlightCheck(at location: CLLocation, completion: @escaping (Bool) -> Void) {
        fetchFlightsFromOpenSky(near: location) { result in
            switch result {
            case .success(let flights):
                // In background, only check for very close flights
                let closeFlights = flights.within(radius: 5000, of: location) // 5km for background
                
                if let nearestFlight = closeFlights.first {
                    NotificationService.shared.sendFlightNotification(
                        for: nearestFlight,
                        distance: nearestFlight.distanceFrom(location: location) ?? 0
                    )
                }
                
                completion(true)
            case .failure(let error):
                print("Background flight check failed: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
}

// MARK: - Flight Service Errors

enum FlightServiceError: LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noData:
            return "No data received from flight API"
        case .invalidResponse:
            return "Invalid response from flight API"
        case .rateLimitExceeded:
            return "API rate limit exceeded"
        }
    }
}

// MARK: - Aircraft Database Integration

extension FlightService {
    func enrichFlightWithAircraftData(_ flight: Flight, completion: @escaping (Flight) -> Void) {
        // In a real implementation, you might call additional APIs here
        // For now, we'll use the built-in aircraft data generation
        completion(flight)
    }
    
    func getAircraftInfo(for icao24: String) -> Aircraft? {
        // Basic aircraft lookup - in a real app, you might have a local database
        // or call additional APIs like AirLabs or AviationStack for more detailed info
        return Aircraft(icao24: icao24)
    }
} 