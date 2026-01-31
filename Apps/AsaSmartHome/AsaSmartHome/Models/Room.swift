import Foundation
import SwiftData

// MARK: - Room Model

/// 部屋モデル - デバイスをグループ化するための単位
@Model
final class Room {
    // MARK: - Properties

    @Attribute(.unique) var id: UUID
    var name: String
    var roomTypeRawValue: String
    var sortOrder: Int
    var createdAt: Date

    // MARK: - Computed Properties

    var roomType: RoomType {
        get { RoomType(rawValue: roomTypeRawValue) ?? .other }
        set { roomTypeRawValue = newValue.rawValue }
    }

    var iconName: String {
        roomType.iconName
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        roomType: RoomType = .other,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.roomTypeRawValue = roomType.rawValue
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}

// MARK: - Equatable

extension Room: Equatable {
    static func == (lhs: Room, rhs: Room) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sample Data

extension Room {
    /// サンプルデータ生成
    static func sampleRooms() -> [Room] {
        [
            Room(name: "リビング", roomType: .livingRoom, sortOrder: 0),
            Room(name: "寝室", roomType: .bedroom, sortOrder: 1),
            Room(name: "キッチン", roomType: .kitchen, sortOrder: 2),
            Room(name: "書斎", roomType: .office, sortOrder: 3),
            Room(name: "子供部屋", roomType: .kids, sortOrder: 4),
            Room(name: "玄関", roomType: .other, sortOrder: 5)
        ]
    }
}
