import Foundation

struct Memo: Identifiable, Codable {
    let id = UUID()
    let content: String
    let createdAt: Date
}
