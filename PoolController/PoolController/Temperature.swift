import Foundation

// MARK: - Temperature Models
struct TemperatureReading: Codable {
    let current: Double?
    let setPoint: Double?
    let units: String
    let isHeating: Bool
    let isCooling: Bool
    
    enum CodingKeys: String, CodingKey {
        case current, setPoint, units, isHeating, isCooling
    }
}

struct TemperatureRange: Codable {
    let min: Double
    let max: Double
    let units: String
    
    enum CodingKeys: String, CodingKey {
        case min, max, units
    }
}

// MARK: - Temperature Extensions
extension Double {
    func formatTemperature(units: String = "F", showUnits: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        
        guard let formattedNumber = formatter.string(from: NSNumber(value: self)) else {
            return "--"
        }
        
        return showUnits ? "\(formattedNumber)°\(units)" : formattedNumber
    }
}

// MARK: - Temperature Conversion
extension Double {
    func celsiusToFahrenheit() -> Double {
        return (self * 9/5) + 32
    }
    
    func fahrenheitToCelsius() -> Double {
        return (self - 32) * 5/9
    }
}