import Foundation

// MARK: - Aircraft Model

struct Aircraft: Codable, Identifiable {
    let id: String
    let icao24: String
    let registration: String?
    let manufacturer: String?
    let model: String?
    let aircraftType: String?
    let operatorName: String?
    let facts: [AircraftFact]
    let specs: AircraftSpecs?
    
    init(icao24: String, registration: String? = nil, manufacturer: String? = nil, model: String? = nil) {
        self.id = icao24
        self.icao24 = icao24
        self.registration = registration
        self.manufacturer = manufacturer
        self.model = model
        self.aircraftType = nil
        self.operatorName = nil
        self.specs = AircraftSpecs.forModel(model)
        self.facts = AircraftFactGenerator.generateFacts(
            icao24: icao24,
            manufacturer: manufacturer,
            model: model,
            specs: AircraftSpecs.forModel(model)
        )
    }
}

// MARK: - Aircraft Specifications

struct AircraftSpecs: Codable {
    let maxPassengers: Int?
    let maxSpeed: Int? // km/h
    let range: Int? // km
    let wingspan: Double? // meters
    let length: Double? // meters
    let maxAltitude: Int? // feet
    let engines: Int?
    let firstFlight: String?
    
    static func forModel(_ model: String?) -> AircraftSpecs? {
        guard let model = model else { return nil }
        
        // Basic aircraft specifications database
        let specs: [String: AircraftSpecs] = [
            "Boeing 737": AircraftSpecs(
                maxPassengers: 189,
                maxSpeed: 876,
                range: 6570,
                wingspan: 35.8,
                length: 39.5,
                maxAltitude: 41000,
                engines: 2,
                firstFlight: "1967"
            ),
            "Boeing 777": AircraftSpecs(
                maxPassengers: 396,
                maxSpeed: 905,
                range: 17370,
                wingspan: 64.8,
                length: 73.9,
                maxAltitude: 43100,
                engines: 2,
                firstFlight: "1994"
            ),
            "Airbus A320": AircraftSpecs(
                maxPassengers: 180,
                maxSpeed: 871,
                range: 6150,
                wingspan: 35.8,
                length: 37.6,
                maxAltitude: 39800,
                engines: 2,
                firstFlight: "1987"
            ),
            "Airbus A380": AircraftSpecs(
                maxPassengers: 853,
                maxSpeed: 945,
                range: 15200,
                wingspan: 79.8,
                length: 72.7,
                maxAltitude: 43000,
                engines: 4,
                firstFlight: "2005"
            )
        ]
        
        // Try exact match first
        if let exactSpecs = specs[model] {
            return exactSpecs
        }
        
        // Try partial matches
        for (key, value) in specs {
            if model.contains(key) || key.contains(model) {
                return value
            }
        }
        
        return nil
    }
}

// MARK: - Aircraft Facts

struct AircraftFact: Codable {
    let title: String
    let description: String
    let category: FactCategory
}

enum FactCategory: String, Codable, CaseIterable {
    case specifications = "specifications"
    case history = "history"
    case interesting = "interesting"
    case safety = "safety"
    case environmental = "environmental"
}

// MARK: - Aircraft Fact Generator

class AircraftFactGenerator {
    static func generateFacts(icao24: String, manufacturer: String?, model: String?, specs: AircraftSpecs?) -> [AircraftFact] {
        var facts: [AircraftFact] = []
        
        // Add specification-based facts
        if let specs = specs {
            facts.append(contentsOf: generateSpecsFacts(specs: specs, model: model))
        }
        
        // Add model-specific facts
        if let model = model {
            facts.append(contentsOf: generateModelFacts(model: model))
        }
        
        // Add general aviation facts
        facts.append(contentsOf: getRandomGeneralFacts())
        
        return facts
    }
    
    static func generateFacts(for aircraft: Aircraft) -> [AircraftFact] {
        return generateFacts(
            icao24: aircraft.icao24,
            manufacturer: aircraft.manufacturer,
            model: aircraft.model,
            specs: aircraft.specs
        )
    }
    
    private static func generateSpecsFacts(specs: AircraftSpecs, model: String?) -> [AircraftFact] {
        var facts: [AircraftFact] = []
        
        if let maxPassengers = specs.maxPassengers {
            facts.append(AircraftFact(
                title: "Passenger Capacity",
                description: "This aircraft can carry up to \(maxPassengers) passengers.",
                category: .specifications
            ))
        }
        
        if let maxSpeed = specs.maxSpeed {
            facts.append(AircraftFact(
                title: "Top Speed",
                description: "Maximum cruising speed is \(maxSpeed) km/h (\(Int(Double(maxSpeed) * 0.539957)) knots).",
                category: .specifications
            ))
        }
        
        if let range = specs.range {
            facts.append(AircraftFact(
                title: "Flight Range",
                description: "This aircraft has a maximum range of \(range) kilometers.",
                category: .specifications
            ))
        }
        
        if let wingspan = specs.wingspan {
            facts.append(AircraftFact(
                title: "Wingspan",
                description: "The wingspan measures \(wingspan) meters across.",
                category: .specifications
            ))
        }
        
        return facts
    }
    
    private static func generateModelFacts(model: String) -> [AircraftFact] {
        let modelFacts: [String: [AircraftFact]] = [
            "Boeing 737": [
                AircraftFact(
                    title: "Most Popular Airliner",
                    description: "The Boeing 737 is the best-selling commercial airliner in history with over 10,000 delivered.",
                    category: .history
                ),
                AircraftFact(
                    title: "Short to Medium Haul",
                    description: "Designed for short to medium-haul flights, perfect for domestic and regional routes.",
                    category: .specifications
                )
            ],
            "Boeing 777": [
                AircraftFact(
                    title: "Twin Engine Giant",
                    description: "The 777 was the first commercial aircraft designed entirely on computers.",
                    category: .history
                ),
                AircraftFact(
                    title: "ETOPS Capable",
                    description: "Can fly over water for up to 330 minutes on one engine - that's over 5 hours!",
                    category: .safety
                )
            ],
            "Airbus A320": [
                AircraftFact(
                    title: "Fly-by-Wire Pioneer",
                    description: "First commercial aircraft to use fly-by-wire flight controls as standard.",
                    category: .history
                ),
                AircraftFact(
                    title: "Sidestick Controls",
                    description: "Uses sidestick controls instead of traditional yokes for pilot input.",
                    category: .specifications
                )
            ],
            "Airbus A380": [
                AircraftFact(
                    title: "World's Largest Passenger Jet",
                    description: "The A380 is the world's largest passenger airliner with two full-length decks.",
                    category: .specifications
                ),
                AircraftFact(
                    title: "Four Massive Engines",
                    description: "Powered by four huge engines, each one as powerful as three Formula 1 cars!",
                    category: .interesting
                )
            ]
        ]
        
        // Try exact match first
        if let facts = modelFacts[model] {
            return facts
        }
        
        // Try partial matches
        for (key, facts) in modelFacts {
            if model.contains(key) || key.contains(model) {
                return facts
            }
        }
        
        return []
    }
    
    private static func getRandomGeneralFacts() -> [AircraftFact] {
        let generalFacts = [
            AircraftFact(
                title: "Cruising Altitude",
                description: "Commercial aircraft typically cruise between 30,000 and 42,000 feet above sea level.",
                category: .specifications
            ),
            AircraftFact(
                title: "Lightning Strikes",
                description: "Aircraft are struck by lightning about once per year, but are designed to handle it safely.",
                category: .safety
            ),
            AircraftFact(
                title: "Fuel Efficiency",
                description: "Modern aircraft are about 80% more fuel efficient per passenger-mile than they were in the 1960s.",
                category: .environmental
            ),
            AircraftFact(
                title: "Autopilot Usage",
                description: "Most commercial flights use autopilot for about 90% of the journey.",
                category: .interesting
            ),
            AircraftFact(
                title: "Black Boxes",
                description: "Flight recorders are actually bright orange to make them easier to find after an incident.",
                category: .safety
            )
        ]
        
        return Array(generalFacts.shuffled().prefix(2))
    }
}

// MARK: - Aircraft Extensions

extension Aircraft {
    var displayName: String {
        if let manufacturer = manufacturer, let model = model {
            return "\(manufacturer) \(model)"
        } else if let model = model {
            return model
        } else if let registration = registration {
            return registration
        } else {
            return "Unknown Aircraft"
        }
    }
    
    var randomFact: AircraftFact? {
        return facts.randomElement()
    }
    
    func factsOfCategory(_ category: FactCategory) -> [AircraftFact] {
        return facts.filter { $0.category == category }
    }
} 