import Foundation
import SwiftData

@Model
final class Like: Identifiable {
    var id: UUID
    var userName: String
    var createdAt: Date

    // MARK: - Swift Data リレーション（多対1）

    var post: Post?

    // MARK: - Initializer

    init(userName: String) {
        self.id = UUID()
        self.userName = userName
        self.createdAt = Date()
    }

    // MARK: - Computed Properties

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: createdAt)
    }
}
