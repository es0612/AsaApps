import Foundation

struct Quote: Codable, Identifiable {
    let id = UUID()
    let text: String
    var isFavorite: Bool
    let timestamp: Date
}
