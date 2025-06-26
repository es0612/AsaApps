
import Foundation

struct WaterLog: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var amount: Double // ml
}
