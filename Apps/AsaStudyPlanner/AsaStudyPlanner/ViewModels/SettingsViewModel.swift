import Foundation
import SwiftUI

/// 設定画面のViewModel
@MainActor
@Observable
final class SettingsViewModel {

    // MARK: - Dependencies

    private let dataService: DataService

    // MARK: - State

    private(set) var profile: UserLearningProfile?
    private(set) var isLoading = false

    // MARK: - UI Binding Properties

    var morningStartHour: Int {
        get { profile?.morningStartHour ?? 5 }
        set { profile?.morningStartHour = newValue; saveProfile() }
    }

    var morningStartMinute: Int {
        get { profile?.morningStartMinute ?? 30 }
        set { profile?.morningStartMinute = newValue; saveProfile() }
    }

    var morningGoalMinutes: Int {
        get { profile?.morningGoalMinutes ?? 60 }
        set { profile?.morningGoalMinutes = newValue; saveProfile() }
    }

    var morningReminderEnabled: Bool {
        get { profile?.morningReminderEnabled ?? true }
        set { profile?.morningReminderEnabled = newValue; saveProfile() }
    }

    var dailyGoalMinutes: Int {
        get { profile?.dailyGoalMinutes ?? 120 }
        set { profile?.dailyGoalMinutes = newValue; saveProfile() }
    }

    var weeklyGoalMinutes: Int {
        get { profile?.weeklyGoalMinutes ?? 600 }
        set { profile?.weeklyGoalMinutes = newValue; saveProfile() }
    }

    var aiOptimizationEnabled: Bool {
        get { profile?.aiOptimizationEnabled ?? true }
        set { profile?.aiOptimizationEnabled = newValue; saveProfile() }
    }

    var optimizationPreset: OptimizationPreset {
        get { profile?.optimizationPreset ?? .default }
        set { profile?.optimizationPreset = newValue; saveProfile() }
    }

    var studyReminderEnabled: Bool {
        get { profile?.studyReminderEnabled ?? true }
        set { profile?.studyReminderEnabled = newValue; saveProfile() }
    }

    var reviewReminderEnabled: Bool {
        get { profile?.reviewReminderEnabled ?? true }
        set { profile?.reviewReminderEnabled = newValue; saveProfile() }
    }

    var achievementNotificationEnabled: Bool {
        get { profile?.achievementNotificationEnabled ?? true }
        set { profile?.achievementNotificationEnabled = newValue; saveProfile() }
    }

    var defaultSessionMinutes: Int {
        get { profile?.defaultSessionMinutes ?? 25 }
        set { profile?.defaultSessionMinutes = newValue; saveProfile() }
    }

    var breakReminderEnabled: Bool {
        get { profile?.breakReminderEnabled ?? true }
        set { profile?.breakReminderEnabled = newValue; saveProfile() }
    }

    var breakIntervalMinutes: Int {
        get { profile?.breakIntervalMinutes ?? 25 }
        set { profile?.breakIntervalMinutes = newValue; saveProfile() }
    }

    // MARK: - Computed Properties

    var morningStartTime: Date {
        get {
            var components = DateComponents()
            components.hour = morningStartHour
            components.minute = morningStartMinute
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            morningStartHour = components.hour ?? 5
            morningStartMinute = components.minute ?? 30
        }
    }

    var effectiveWeights: OptimizationWeights {
        profile?.effectiveWeights ?? .default
    }

    // MARK: - Initializer

    init(dataService: DataService) {
        self.dataService = dataService
    }

    /// メインアクターコンテキストで使用するデフォルト初期化
    init() {
        self.dataService = DataService()
    }

    // MARK: - Data Loading

    func loadData() {
        isLoading = true
        profile = dataService.fetchOrCreateProfile()
        isLoading = false
    }

    // MARK: - Save

    private func saveProfile() {
        profile?.update()
        dataService.save()
    }

    // MARK: - Actions

    func resetToDefaults() {
        guard let profile = profile else { return }

        profile.morningStartHour = 5
        profile.morningStartMinute = 30
        profile.morningGoalMinutes = 60
        profile.morningReminderEnabled = true

        profile.dailyGoalMinutes = 120
        profile.weeklyGoalMinutes = 600

        profile.aiOptimizationEnabled = true
        profile.optimizationPreset = .default
        profile.customWeights = nil

        profile.studyReminderEnabled = true
        profile.reviewReminderEnabled = true
        profile.achievementNotificationEnabled = true

        profile.defaultSessionMinutes = 25
        profile.breakReminderEnabled = true
        profile.breakIntervalMinutes = 25

        saveProfile()
    }

    func deleteAllData() {
        dataService.deleteAllData()
    }

    // MARK: - Custom Weights

    func setCustomWeights(_ weights: OptimizationWeights) {
        profile?.customWeights = weights
        profile?.optimizationPreset = .custom
        saveProfile()
    }

    func clearCustomWeights() {
        profile?.customWeights = nil
        if profile?.optimizationPreset == .custom {
            profile?.optimizationPreset = .default
        }
        saveProfile()
    }
}
