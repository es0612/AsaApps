import Foundation
import SwiftData

// MARK: - リマインダーモデル

/// 位置情報に紐付くリマインダー
/// 場所への到着・離脱時に通知をトリガーする
@Model
public final class LocationReminder {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var note: String?
    public var triggerOnEntry: Bool
    public var triggerOnExit: Bool
    public var isRepeating: Bool
    public var isCompleted: Bool
    public var completedAt: Date?
    public var isActive: Bool
    public var lastTriggeredAt: Date?
    public var triggerCount: Int
    public var notificationIdentifier: String?
    public var location: ReminderLocation?
    public var createdAt: Date
    public var updatedAt: Date

    // MARK: - Computed Properties

    /// トリガー種別の表示文字列
    public var triggerDescription: String {
        switch (triggerOnEntry, triggerOnExit) {
        case (true, true): "到着・離脱時"
        case (true, false): "到着時"
        case (false, true): "離脱時"
        case (false, false): "無効"
        }
    }

    /// リマインダーが有効かどうか（アクティブかつ未完了）
    public var isEffective: Bool {
        isActive && !isCompleted
    }

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        title: String,
        note: String? = nil,
        triggerOnEntry: Bool = true,
        triggerOnExit: Bool = false,
        isRepeating: Bool = false,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        isActive: Bool = true,
        lastTriggeredAt: Date? = nil,
        triggerCount: Int = 0,
        notificationIdentifier: String? = nil,
        location: ReminderLocation? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.triggerOnEntry = triggerOnEntry
        self.triggerOnExit = triggerOnExit
        self.isRepeating = isRepeating
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.isActive = isActive
        self.lastTriggeredAt = lastTriggeredAt
        self.triggerCount = triggerCount
        self.notificationIdentifier = notificationIdentifier
        self.location = location
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Methods

    /// リマインダーを完了にする
    public func markCompleted() {
        isCompleted = true
        completedAt = Date()
        isActive = false
        updatedAt = Date()
    }

    /// リマインダーを未完了に戻す
    public func markIncomplete() {
        isCompleted = false
        completedAt = nil
        isActive = true
        updatedAt = Date()
    }

    /// トリガー発火を記録
    public func recordTrigger() {
        triggerCount += 1
        lastTriggeredAt = Date()
        updatedAt = Date()
        if !isRepeating {
            markCompleted()
        }
    }
}
