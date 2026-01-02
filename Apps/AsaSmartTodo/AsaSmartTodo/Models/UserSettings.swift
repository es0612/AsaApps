//
//  UserSettings.swift
//  AsaSmartTodo
//
//  ユーザー設定の永続化モデル
//  AI予測の重み、通知設定、UI設定を管理
//

import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID
    var createdAt: Date

    // MARK: - AI予測の重み設定（合計100%）

    var dueDateWeight: Double           // デフォルト: 0.35 (35%)
    var categoryWeight: Double          // デフォルト: 0.20 (20%)
    var titleComplexityWeight: Double   // デフォルト: 0.15 (15%)
    var descriptionWeight: Double       // デフォルト: 0.10 (10%)
    var timeOfDayWeight: Double         // デフォルト: 0.10 (10%)
    var historicalWeight: Double        // デフォルト: 0.10 (10%)

    // MARK: - 通知設定

    var notificationsEnabled: Bool      // デフォルト: false
    var notificationHour: Int           // デフォルト: 9
    var notificationMinute: Int         // デフォルト: 0
    var dueDayReminderEnabled: Bool     // 期限日リマインダー
    var oneDayBeforeReminderEnabled: Bool // 1日前リマインダー
    var morningReminderEnabled: Bool    // 朝活リマインダー（5:00-7:00）
    var morningReminderTime: Date       // 朝活リマインダー時刻

    // MARK: - UI設定

    var showCompletedTasks: Bool        // デフォルト: true
    var defaultCategory: String         // デフォルト: "work"
    var sortOrder: String               // デフォルト: "priority"

    init() {
        self.id = UUID()
        self.createdAt = Date()

        // AI重み設定のデフォルト値
        self.dueDateWeight = 0.35
        self.categoryWeight = 0.20
        self.titleComplexityWeight = 0.15
        self.descriptionWeight = 0.10
        self.timeOfDayWeight = 0.10
        self.historicalWeight = 0.10

        // 通知設定のデフォルト値
        self.notificationsEnabled = false
        self.notificationHour = 9
        self.notificationMinute = 0
        self.dueDayReminderEnabled = true
        self.oneDayBeforeReminderEnabled = true
        self.morningReminderEnabled = false
        self.morningReminderTime = Calendar.current.date(from: DateComponents(hour: 6, minute: 0)) ?? Date()

        // UI設定のデフォルト値
        self.showCompletedTasks = true
        self.defaultCategory = "work"
        self.sortOrder = "priority"
    }

    // MARK: - Computed Properties

    /// PriorityWeightsへの変換
    var priorityWeights: PriorityWeights {
        PriorityWeights(
            dueDateWeight: dueDateWeight,
            categoryWeight: categoryWeight,
            titleComplexityWeight: titleComplexityWeight,
            descriptionWeight: descriptionWeight,
            timeOfDayWeight: timeOfDayWeight,
            historicalWeight: historicalWeight
        )
    }

    /// 重み合計の計算
    var totalWeights: Double {
        dueDateWeight + categoryWeight + titleComplexityWeight +
        descriptionWeight + timeOfDayWeight + historicalWeight
    }

    /// 重み合計が100%かどうかの検証（許容誤差0.01）
    var isWeightsValid: Bool {
        abs(totalWeights - 1.0) < 0.01
    }
}
