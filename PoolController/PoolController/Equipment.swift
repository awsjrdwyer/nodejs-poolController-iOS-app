import Foundation

// MARK: - Equipment Control Models
struct EquipmentControl: Codable {
    let id: Int
    let name: String
    let isOn: Bool
}

// MARK: - Light Control
struct LightGroup: Codable, Identifiable {
    let id: Int
    let name: String
    let type: String
    let isOn: Bool
    let lightingTheme: String?
    let color: LightColor?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, isOn, lightingTheme, color
    }
}

struct LightColor: Codable {
    let name: String
    let red: Int
    let green: Int
    let blue: Int
    
    enum CodingKeys: String, CodingKey {
        case name, red, green, blue
    }
}

// MARK: - Chemistry
struct Chemistry: Codable {
    let ph: ChemistryReading
    let orp: ChemistryReading
    let saturationIndex: Double?
    let alkalinity: ChemistryReading?
    let cyanuricAcid: ChemistryReading?
    let calcium: ChemistryReading?
    
    enum CodingKeys: String, CodingKey {
        case ph, orp, saturationIndex, alkalinity, cyanuricAcid, calcium
    }
}

struct ChemistryReading: Codable {
    let level: Double?
    let setpoint: Double?
    let tank: ChemistryTank?
    let probe: ChemistryProbe?
    
    enum CodingKeys: String, CodingKey {
        case level, setpoint, tank, probe
    }
}

struct ChemistryTank: Codable {
    let level: Int?
    let capacity: Int?
    let units: String?
    
    enum CodingKeys: String, CodingKey {
        case level, capacity, units
    }
}

struct ChemistryProbe: Codable {
    let level: Double?
    let tempComp: Double?
    let slope: Double?
    
    enum CodingKeys: String, CodingKey {
        case level, tempComp, slope
    }
}

// MARK: - Heater
struct Heater: Codable, Identifiable {
    let id: Int
    let name: String
    let type: String
    let isOn: Bool
    let isVirtual: Bool
    let freeze: Bool
    let coolingEnabled: Bool
    let efficiency: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, isOn, isVirtual, freeze, coolingEnabled, efficiency
    }
}

// MARK: - Valve
struct Valve: Codable, Identifiable {
    let id: Int
    let name: String
    let type: String
    let isDiverted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, isDiverted
    }
}