import Foundation

struct Habit: Codable, Identifiable {
    let id = UUID()
    let name: String
    var isChecked: Bool
    let date: Date
}
