import Foundation

struct Category: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let name: String
    let iconName: String
    let sortOrder: Int

    // MARK: - Default Categories

    static let defaultCategories: [Category] = [
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "すべて", iconName: "square.grid.2x2", sortOrder: 0),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "家電", iconName: "desktopcomputer", sortOrder: 1),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "ファッション", iconName: "tshirt", sortOrder: 2),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, name: "食品", iconName: "fork.knife", sortOrder: 3),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!, name: "本・雑誌", iconName: "book", sortOrder: 4),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!, name: "スポーツ", iconName: "sportscourt", sortOrder: 5),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!, name: "キッズ", iconName: "figure.2.and.child.holdinghands", sortOrder: 6)
    ]

    static var allCategory: Category {
        defaultCategories.first!
    }
}
