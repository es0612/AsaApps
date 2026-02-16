import Foundation
import SwiftData

// MARK: - 朝活ルーティンアイテム

@Model
public final class MorningRoutineItem {
    public var id: UUID
    public var title: String
    public var order: Int
    public var statusRawValue: String
    public var estimatedMinutes: Int
    public var actualMinutes: Int?
    public var iconName: String
    public var routine: MorningRoutine?

    public init(
        id: UUID = UUID(),
        title: String = "",
        order: Int = 0,
        statusRawValue: String = RoutineItemStatus.pending.rawValue,
        estimatedMinutes: Int = 10,
        actualMinutes: Int? = nil,
        iconName: String = "circle",
        routine: MorningRoutine? = nil
    ) {
        self.id = id
        self.title = title
        self.order = order
        self.statusRawValue = statusRawValue
        self.estimatedMinutes = estimatedMinutes
        self.actualMinutes = actualMinutes
        self.iconName = iconName
        self.routine = routine
    }

    // MARK: - Computed Properties

    public var status: RoutineItemStatus {
        get { RoutineItemStatus(rawValue: statusRawValue) ?? .pending }
        set { statusRawValue = newValue.rawValue }
    }
}
