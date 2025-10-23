import Foundation

// MARK: - Helper to create PoolState with schedules
func PoolStateWithSchedules(from originalState: PoolState, schedules: [Schedule]) -> PoolState {
    return PoolState(
        systemUnits: originalState.systemUnits,
        startTime: originalState.startTime,
        time: originalState.time,
        status: originalState.status,
        mode: originalState.mode,
        appVersion: originalState.appVersion,
        controllerType: originalState.controllerType,
        model: originalState.model,
        temps: originalState.temps,
        circuits: originalState.circuits,
        features: originalState.features,
        pumps: originalState.pumps,
        schedules: schedules,  // Use the fetched schedules
        bodies: originalState.bodies,
        equipment: originalState.equipment
    )
}

// MARK: - Main Pool State
struct PoolState: Codable {
    let systemUnits: SystemUnits?
    let startTime: String?
    let time: String?
    let status: StatusInfo?
    let mode: ModeInfo?
    let appVersion: String?
    let controllerType: String?
    let model: String?
    let temps: Temperatures?
    let circuits: [Circuit]?
    let features: [Feature]?
    let pumps: [Pump]?
    let schedules: [Schedule]?
    let bodies: [Body]?
    let equipment: Equipment?
    
    // Regular initializer for creating PoolState programmatically
    init(systemUnits: SystemUnits?, startTime: String?, time: String?, status: StatusInfo?, mode: ModeInfo?, 
         appVersion: String?, controllerType: String?, model: String?, temps: Temperatures?, 
         circuits: [Circuit]?, features: [Feature]?, pumps: [Pump]?, schedules: [Schedule]?, bodies: [Body]?, equipment: Equipment?) {
        self.systemUnits = systemUnits
        self.startTime = startTime
        self.time = time
        self.status = status
        self.mode = mode
        self.appVersion = appVersion
        self.controllerType = controllerType
        self.model = model
        self.temps = temps
        self.circuits = circuits
        self.features = features
        self.pumps = pumps
        self.schedules = schedules
        self.bodies = bodies
        self.equipment = equipment
    }
    
    // Use a custom decoder to handle missing or unexpected fields gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        systemUnits = try container.decodeIfPresent(SystemUnits.self, forKey: .systemUnits)
        startTime = try container.decodeIfPresent(String.self, forKey: .startTime)
        time = try container.decodeIfPresent(String.self, forKey: .time)
        status = try container.decodeIfPresent(StatusInfo.self, forKey: .status)
        mode = try container.decodeIfPresent(ModeInfo.self, forKey: .mode)
        appVersion = try container.decodeIfPresent(String.self, forKey: .appVersion)
        controllerType = try container.decodeIfPresent(String.self, forKey: .controllerType)
        model = try container.decodeIfPresent(String.self, forKey: .model)
        
        // Try to decode arrays, but don't fail if they're missing or malformed
        temps = try? container.decodeIfPresent(Temperatures.self, forKey: .temps)
        circuits = (try? container.decodeIfPresent([Circuit].self, forKey: .circuits)) ?? []
        features = (try? container.decodeIfPresent([Feature].self, forKey: .features)) ?? []
        pumps = (try? container.decodeIfPresent([Pump].self, forKey: .pumps)) ?? []
        // Try to decode schedules with detailed error handling
        do {
            schedules = try container.decodeIfPresent([Schedule].self, forKey: .schedules) ?? []
            print("📅 Successfully decoded \(schedules?.count ?? 0) schedules")
        } catch {
            print("📅 Failed to decode schedules: \(error)")
            schedules = []
        }
        bodies = (try? container.decodeIfPresent([Body].self, forKey: .bodies)) ?? []
        equipment = try? container.decodeIfPresent(Equipment.self, forKey: .equipment)
    }
    
    enum CodingKeys: String, CodingKey {
        case systemUnits, startTime, time, status, mode, appVersion, controllerType, model
        case temps, circuits, features, pumps, schedules, bodies, equipment
    }
}

// MARK: - System Units
struct SystemUnits: Codable {
    let val: Int
    let name: String
    let desc: String
    
    enum CodingKeys: String, CodingKey {
        case val, name, desc
    }
}

// MARK: - Status Info
struct StatusInfo: Codable {
    let val: Int
    let name: String
    let desc: String
    let percent: Int?
    
    enum CodingKeys: String, CodingKey {
        case val, name, desc, percent
    }
}

// MARK: - Mode Info
struct ModeInfo: Codable {
    let val: Int
    let name: String
    let desc: String
    
    enum CodingKeys: String, CodingKey {
        case val, name, desc
    }
}

// MARK: - Equipment
struct Equipment: Codable {
    let model: String?
    let controllerType: String?
    let shared: Bool?
    let dual: Bool?
    let messages: [SystemMessage]?
    
    enum CodingKeys: String, CodingKey {
        case model, controllerType, shared, dual, messages
    }
}

// MARK: - System Messages
struct SystemMessage: Codable, Identifiable {
    let id: Int
    let message: String
    let level: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id, message, level, timestamp
    }
}

// MARK: - Temperatures
struct Temperatures: Codable {
    let air: Double?
    let solar: Double?
    let units: TemperatureUnits?
    let bodies: [Body]?
    
    enum CodingKeys: String, CodingKey {
        case air, solar, units, bodies
    }
}

struct TemperatureUnits: Codable {
    let val: Int?
    let name: String
    let desc: String?
    
    enum CodingKeys: String, CodingKey {
        case val, name, desc
    }
}

// MARK: - Body (Pool/Spa)
struct Body: Codable, Identifiable {
    let id: Int
    let name: String?
    let type: BodyType?
    let temp: Double?
    let setPoint: Double?
    let heatMode: BodyHeatMode?
    let heatStatus: BodyHeatStatus?
    let isOn: Bool?
    let capacity: Int?
    let heaterOptions: HeaterOptions?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, temp, setPoint, heatMode, heatStatus, isOn, capacity, heaterOptions
    }
}

// MARK: - Body Type
struct BodyType: Codable {
    let val: Int?
    let name: String?
    let desc: String?
    
    enum CodingKeys: String, CodingKey {
        case val, name, desc
    }
}

// MARK: - Body Heat Mode
struct BodyHeatMode: Codable {
    let val: Int?
    let name: String?
    let desc: String?
    
    enum CodingKeys: String, CodingKey {
        case val, name, desc
    }
}

// MARK: - Body Heat Status
struct BodyHeatStatus: Codable {
    let val: Int?
    let name: String?
    let desc: String?
    
    enum CodingKeys: String, CodingKey {
        case val, name, desc
    }
}

struct HeaterOptions: Codable {
    let gas: Int?
    let solar: Int?
    let heatPump: Int?
    
    enum CodingKeys: String, CodingKey {
        case gas, solar, heatPump
    }
}

// MARK: - Circuit
struct Circuit: Codable, Identifiable {
    let id: Int
    let name: String?
    let type: CircuitType?
    let isOn: Bool?
    let showInFeatures: Bool?
    let freeze: Bool?
    let macro: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, isOn, showInFeatures, freeze, macro
    }
}

// MARK: - Circuit Type
struct CircuitType: Codable {
    let val: Int?
    let name: String?
    let desc: String?
    
    enum CodingKeys: String, CodingKey {
        case val, name, desc
    }
}

// MARK: - Feature
struct Feature: Codable, Identifiable {
    let id: Int
    let name: String?
    let type: FeatureType?
    let isOn: Bool?
    let showInFeatures: Bool?
    let freeze: Bool?
    let macro: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, isOn, showInFeatures, freeze, macro
    }
}

// MARK: - Feature Type
struct FeatureType: Codable {
    let val: Int?
    let name: String?
    let desc: String?
    
    enum CodingKeys: String, CodingKey {
        case val, name, desc
    }
}

// MARK: - Pump
struct Pump: Codable, Identifiable {
    let id: Int
    let name: String?
    let type: PumpType?
    let status: PumpStatus?
    let rpm: Int?
    let watts: Int?
    let flow: Int?
    let ppc: Int?
    let command: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, status, rpm, watts, flow, ppc, command
    }
}

// MARK: - Pump Type
struct PumpType: Codable {
    let val: Int?
    let name: String?
    let desc: String?
    
    enum CodingKeys: String, CodingKey {
        case val, name, desc
    }
}

// MARK: - Pump Status
struct PumpStatus: Codable {
    let val: Int?
    let name: String?
    let desc: String?
    
    enum CodingKeys: String, CodingKey {
        case val, name, desc
    }
}

// MARK: - Schedule
struct Schedule: Codable, Identifiable {
    let id: Int
    let name: String?
    let circuitId: Int?  // Circuit ID number (extracted from circuit object)
    let circuitName: String?  // Circuit name (extracted from circuit object)
    let startTime: Int?  // Time in minutes from midnight
    let endTime: Int?    // Time in minutes from midnight
    let scheduleDaysValue: Int?  // Bitmask for days of week (extracted from scheduleDays object)
    let scheduleTypeName: String?  // Schedule type name (extracted from scheduleType object)
    let isActive: Bool?
    let disabled: Bool?
    let startDate: String?
    let endDate: String?
    let startTimeOffset: Int?
    let endTimeOffset: Int?
    let changeHeatSetpoint: Bool?
    let heatSetpoint: Int?
    let isOn: Bool?
    let triggered: Bool?
    
    // Custom decoder to handle the complex JSON structure from /state/all
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Basic fields
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        disabled = try container.decodeIfPresent(Bool.self, forKey: .disabled)
        startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        startTimeOffset = try container.decodeIfPresent(Int.self, forKey: .startTimeOffset)
        endTimeOffset = try container.decodeIfPresent(Int.self, forKey: .endTimeOffset)
        changeHeatSetpoint = try container.decodeIfPresent(Bool.self, forKey: .changeHeatSetpoint)
        heatSetpoint = try container.decodeIfPresent(Int.self, forKey: .heatSetpoint)
        isOn = try container.decodeIfPresent(Bool.self, forKey: .isOn)
        triggered = try container.decodeIfPresent(Bool.self, forKey: .triggered)
        
        // Time fields (always Int in the JSON)
        startTime = try container.decodeIfPresent(Int.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Int.self, forKey: .endTime)
        
        // Extract circuit information from complex circuit object
        do {
            let circuitContainer = try container.nestedContainer(keyedBy: CircuitKeys.self, forKey: .circuit)
            circuitId = try? circuitContainer.decodeIfPresent(Int.self, forKey: .id)
            circuitName = try? circuitContainer.decodeIfPresent(String.self, forKey: .name)
        } catch {
            circuitId = nil
            circuitName = nil
        }
        
        // Extract scheduleDays value from complex scheduleDays object
        do {
            let scheduleDaysContainer = try container.nestedContainer(keyedBy: ScheduleDaysKeys.self, forKey: .scheduleDays)
            scheduleDaysValue = try? scheduleDaysContainer.decodeIfPresent(Int.self, forKey: .val)
        } catch {
            scheduleDaysValue = nil
        }
        
        // Extract scheduleType name from complex scheduleType object
        do {
            let scheduleTypeContainer = try container.nestedContainer(keyedBy: ScheduleTypeKeys.self, forKey: .scheduleType)
            scheduleTypeName = try? scheduleTypeContainer.decodeIfPresent(String.self, forKey: .name)
        } catch {
            scheduleTypeName = nil
        }
    }
    
    // Helper coding keys for nested objects
    private enum CircuitKeys: String, CodingKey {
        case id, name
    }
    
    private enum ScheduleDaysKeys: String, CodingKey {
        case val
    }
    
    private enum ScheduleTypeKeys: String, CodingKey {
        case name
    }
    
    private static func timeStringToMinutes(_ timeString: String) -> Int? {
        // Convert "HH:MM" format to minutes from midnight
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hours = Int(components[0]),
              let minutes = Int(components[1]) else {
            return nil
        }
        return hours * 60 + minutes
    }
    
    // Encode method to conform to Encodable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encodeIfPresent(isActive, forKey: .isActive)
        try container.encodeIfPresent(disabled, forKey: .disabled)
        try container.encodeIfPresent(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encodeIfPresent(startTimeOffset, forKey: .startTimeOffset)
        try container.encodeIfPresent(endTimeOffset, forKey: .endTimeOffset)
        try container.encodeIfPresent(changeHeatSetpoint, forKey: .changeHeatSetpoint)
        try container.encodeIfPresent(heatSetpoint, forKey: .heatSetpoint)
        try container.encodeIfPresent(isOn, forKey: .isOn)
        try container.encodeIfPresent(triggered, forKey: .triggered)
    }
    
    // Computed properties to convert to user-friendly formats
    var startTimeFormatted: String {
        guard let startTime = startTime else { return "Unknown" }
        let hours = startTime / 60
        let minutes = startTime % 60
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    var endTimeFormatted: String {
        guard let endTime = endTime else { return "Unknown" }
        let hours = endTime / 60
        let minutes = endTime % 60
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    var scheduleDaysFormatted: String {
        guard let days = scheduleDaysValue else { return "Unknown" }
        if days == 127 { return "Every Day" }  // 127 = all 7 days
        
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var activeDays: [String] = []
        
        for i in 0..<7 {
            if (days & (1 << i)) != 0 {
                activeDays.append(dayNames[i])
            }
        }
        
        return activeDays.joined(separator: ", ")
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, circuit, startTime, endTime, scheduleDays, scheduleType, isActive, disabled, startDate, endDate
        case startTimeOffset, endTimeOffset, changeHeatSetpoint, heatSetpoint, isOn, triggered
    }
}

// MARK: - Schedule Circuit
struct ScheduleCircuit: Codable {
    let val: Int?
    let name: String?
    let desc: String?
    
    enum CodingKeys: String, CodingKey {
        case val, name, desc
    }
}

// MARK: - Schedule Type
struct ScheduleType: Codable {
    let val: Int?
    let name: String?
    let desc: String?
    
    enum CodingKeys: String, CodingKey {
        case val, name, desc
    }
}

// MARK: - Delay
struct Delay: Codable, Identifiable {
    let id: Int
    let name: String?
    let delay: Int?
    let isActive: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, name, delay, isActive
    }
}