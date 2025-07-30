import Foundation
import CoreLocation

// MARK: - Flight Model

struct Flight: Codable, Identifiable, Equatable {
    let id: String
    let callsign: String?
    let origin: String?
    let destination: String?
    let latitude: Double?
    let longitude: Double?
    let altitude: Double?
    let velocity: Double?
    let heading: Double?
    let aircraftInfo: Aircraft?
    let lastUpdated: Date
    
    // Computed properties
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    var location: CLLocation? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocation(latitude: lat, longitude: lon)
    }
    
    var displayName: String {
        return callsign?.trimmingCharacters(in: .whitespaces) ?? "Unknown Flight"
    }
    
    var altitudeString: String {
        guard let altitude = altitude else { return "Unknown" }
        return "\(Int(altitude * 3.28084)) ft" // Convert meters to feet
    }
    
    var velocityString: String {
        guard let velocity = velocity else { return "Unknown" }
        return "\(Int(velocity * 3.6)) km/h" // Convert m/s to km/h
    }
    
    var headingString: String {
        guard let heading = heading else { return "Unknown" }
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((heading + 11.25) / 22.5) % 16
        return "\(Int(heading))° \(directions[index])"
    }
    
    static func == (lhs: Flight, rhs: Flight) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - OpenSky API Response Models

struct OpenSkyResponse: Codable {
    let time: Int
    let states: [[OpenSkyValue]]?
}

enum OpenSkyValue: Codable {
    case string(String)
    case double(Double)
    case int(Int)
    case null
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else {
            self = .null
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let string):
            try container.encode(string)
        case .double(let double):
            try container.encode(double)
        case .int(let int):
            try container.encode(int)
        case .null:
            try container.encodeNil()
        }
    }
    
    var stringValue: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }
    
    var doubleValue: Double? {
        switch self {
        case .double(let value):
            return value
        case .int(let value):
            return Double(value)
        default:
            return nil
        }
    }
    
    var intValue: Int? {
        switch self {
        case .int(let value):
            return value
        case .double(let value):
            return Int(value)
        default:
            return nil
        }
    }
}

// MARK: - Flight Extensions

extension Flight {
    init(from openSkyState: [OpenSkyValue]) {
        // OpenSky API state vector format:
        // 0: icao24, 1: callsign, 2: origin_country, 3: time_position, 4: last_contact,
        // 5: longitude, 6: latitude, 7: baro_altitude, 8: on_ground, 9: velocity,
        // 10: true_track, 11: vertical_rate, 12: sensors, 13: geo_altitude, 14: squawk, 15: spi, 16: position_source
        
        let icao24 = openSkyState[0].stringValue ?? UUID().uuidString
        
        self.id = icao24
        self.callsign = openSkyState.count > 1 ? openSkyState[1].stringValue : nil
        self.origin = openSkyState.count > 2 ? openSkyState[2].stringValue : nil
        self.destination = nil // OpenSky doesn't provide destination
        self.longitude = openSkyState.count > 5 ? openSkyState[5].doubleValue : nil
        self.latitude = openSkyState.count > 6 ? openSkyState[6].doubleValue : nil
        self.altitude = openSkyState.count > 7 ? openSkyState[7].doubleValue : nil
        self.velocity = openSkyState.count > 9 ? openSkyState[9].doubleValue : nil
        self.heading = openSkyState.count > 10 ? openSkyState[10].doubleValue : nil
        self.lastUpdated = Date()
        
        // Create basic aircraft info from ICAO24
        self.aircraftInfo = Aircraft(icao24: icao24)
    }
    
    func distanceFrom(location: CLLocation) -> Double? {
        guard let flightLocation = self.location else { return nil }
        return location.distance(from: flightLocation)
    }
    
    func distanceStringFrom(location: CLLocation) -> String {
        guard let distance = distanceFrom(location: location) else { return "Unknown distance" }
        
        if distance < 1000 {
            return "\(Int(distance)) m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}

// MARK: - Flight Collection Extensions

extension Array where Element == Flight {
    func nearestTo(location: CLLocation) -> Flight? {
        return self.min { flight1, flight2 in
            let distance1 = flight1.distanceFrom(location: location) ?? Double.infinity
            let distance2 = flight2.distanceFrom(location: location) ?? Double.infinity
            return distance1 < distance2
        }
    }
    
    func within(radius: Double, of location: CLLocation) -> [Flight] {
        return self.filter { flight in
            guard let distance = flight.distanceFrom(location: location) else { return false }
            return distance <= radius
        }
    }
    
    func sortedByDistance(from location: CLLocation) -> [Flight] {
        return self.sorted { flight1, flight2 in
            let distance1 = flight1.distanceFrom(location: location) ?? Double.infinity
            let distance2 = flight2.distanceFrom(location: location) ?? Double.infinity
            return distance1 < distance2
        }
    }
} 