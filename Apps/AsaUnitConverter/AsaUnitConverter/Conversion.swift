import Foundation

struct Conversion: Codable, Identifiable {
    let id = UUID()
    let inputValue: Double
    let unitType: String
    let outputValue: Double
    let timestamp: Date
}
