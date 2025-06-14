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
        guard !inputValue.isEmpty, let value = Double(inputValue) else {
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
        inputValue = "" // 成功したら入力クリア
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
    
    func deleteConversion(_ conversion: Conversion) {
        conversions.removeAll { $0.id == conversion.id }
        saveToUserDefaults()
    }
}

