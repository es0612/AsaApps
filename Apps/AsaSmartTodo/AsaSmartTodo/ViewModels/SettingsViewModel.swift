//
//  SettingsViewModel.swift
//  AsaSmartTodo
//
//  設定管理ViewModel
//  AI重み設定、通知管理、カテゴリ管理を統括
//

import Foundation
import SwiftUI
import UserNotifications

@Observable
@MainActor
final class SettingsViewModel {
    var settings: UserSettings
    var customCategories: [CustomCategory] = []
    var notificationAuthStatus: UNAuthorizationStatus = .notDetermined

    private let dataService: DataService
    private let notificationService: NotificationService

    init(dataService: DataService) {
        self.dataService = dataService
        self.notificationService = NotificationService.shared

        // 設定をロード（存在しなければデフォルト作成）
        if let existingSettings = dataService.getUserSettings() {
            self.settings = existingSettings
        } else {
            let newSettings = UserSettings()
            dataService.saveUserSettings(newSettings)
            self.settings = newSettings
        }

        loadCustomCategories()
        Task {
            await updateNotificationStatus()
        }
    }

    // MARK: - 通知関連

    /// 通知権限をリクエスト
    func requestNotificationPermission() async {
        let granted = await notificationService.requestNotificationPermission()
        await updateNotificationStatus()

        if granted {
            settings.notificationsEnabled = true
            await scheduleMorningReminder()
        }
    }

    /// 通知権限の状態を更新
    func updateNotificationStatus() async {
        notificationAuthStatus = await notificationService.getNotificationAuthorizationStatus()
    }

    /// 設定アプリの通知設定画面を開く
    func openNotificationSettings() {
        notificationService.openNotificationSettings()
    }

    /// 朝活リマインダーをスケジュール
    func scheduleMorningReminder() async {
        await notificationService.scheduleMorningReminder(settings: settings)
    }

    /// 通知の有効/無効を切り替え
    func toggleNotifications() async {
        if settings.notificationsEnabled {
            await scheduleMorningReminder()
        } else {
            await notificationService.cancelMorningReminder()
        }
    }

    // MARK: - AI重み設定

    /// AI重みを更新し、SmartTodoViewModelに通知
    func updateAIWeights() {
        // 重み合計が100%になるように正規化
        if !settings.isWeightsValid {
            normalizeWeights()
        }

        // TaskPriorityPredictorに新しい重みを適用
        NotificationCenter.default.post(
            name: .aiWeightsDidChange,
            object: settings.priorityWeights
        )
    }

    /// AI重みをデフォルト値にリセット
    func resetAIWeights() {
        settings.dueDateWeight = 0.35
        settings.categoryWeight = 0.20
        settings.titleComplexityWeight = 0.15
        settings.descriptionWeight = 0.10
        settings.timeOfDayWeight = 0.10
        settings.historicalWeight = 0.10

        updateAIWeights()
    }

    /// 重みを正規化（合計100%に調整）
    private func normalizeWeights() {
        let total = settings.totalWeights
        guard total > 0 else {
            resetAIWeights()
            return
        }

        settings.dueDateWeight /= total
        settings.categoryWeight /= total
        settings.titleComplexityWeight /= total
        settings.descriptionWeight /= total
        settings.timeOfDayWeight /= total
        settings.historicalWeight /= total
    }

    // MARK: - カテゴリ管理

    /// カスタムカテゴリをロード
    func loadCustomCategories() {
        customCategories = dataService.getCustomCategories()
    }

    /// カスタムカテゴリを追加
    func addCustomCategory(
        name: String,
        icon: String,
        importanceWeight: Double,
        colorHex: String
    ) {
        let category = CustomCategory(
            name: name,
            icon: icon,
            importanceWeight: importanceWeight,
            colorHex: colorHex
        )

        dataService.saveCustomCategory(category)
        loadCustomCategories()
    }

    /// カスタムカテゴリを更新
    func updateCustomCategory(_ category: CustomCategory) {
        category.updatedAt = Date()
        dataService.updateCustomCategory(category)
        loadCustomCategories()
    }

    /// カスタムカテゴリを削除
    func deleteCustomCategory(_ category: CustomCategory) {
        guard !category.isSystem else { return }
        dataService.deleteCustomCategory(category)
        loadCustomCategories()
    }

    // MARK: - 設定保存

    /// 設定を保存
    func saveSettings() {
        dataService.updateUserSettings(settings)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let aiWeightsDidChange = Notification.Name("aiWeightsDidChange")
}
