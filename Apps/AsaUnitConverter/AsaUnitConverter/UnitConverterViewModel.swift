import Observation
import Foundation

@Observable
class UnitConverterViewModel {
    var inputValue: String = ""
    var unitType: String = "m→ft"
    var convertedValue: Double = 0.0
    var conversions: [Conversion] = []
    
    let unitTypes = ["m→ft", "kg→lb"]
    
    func convert() {
        guard let value = Double(inputValue), !inputValue.isEmpty else {
            convertedValue = 0.0
            return
        }
        convertedValue = unitType == "m→ft" ? value * 3.28084 : value * 2.20462
        let newConversion = Conversion(
            inputValue: value,
            unitType: unitType,
            outputValue: convertedValue,
            timestamp: Date()
        )
        conversions.append(newConversion)
        saveToUserDefaults()
    }
    
    func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(conversions) {
            UserDefaults.standard.set(data, forKey: "conversions")
        }
    }
    
    func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "conversions"),
           let savedConversions = try? JSONDecoder().decode([Conversion].self, from: data) {
            conversions = savedConversions
        }
    }
}

