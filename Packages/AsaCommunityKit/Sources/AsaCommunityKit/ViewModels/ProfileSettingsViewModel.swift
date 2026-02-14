import Foundation

// MARK: - ProfileSettingsViewModel

/// プロフィール・設定のViewModel
///
/// ユーザープロフィール編集、アプリ設定変更、オンボーディング完了を管理する。
@MainActor @Observable
public final class ProfileSettingsViewModel {
    // MARK: - Dependencies

    private let dataService: CommunityDataServiceProtocol
    private let notificationService: NotificationServiceProtocol

    // MARK: - Properties

    public var profile: CommunityProfile?
    public var settings: CommunitySettings?
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Initialization

    public init(
        dataService: CommunityDataServiceProtocol,
        notificationService: NotificationServiceProtocol
    ) {
        self.dataService = dataService
        self.notificationService = notificationService
    }

    // MARK: - Methods

    /// プロフィールと設定を取得する
    public func loadProfileAndSettings() {
        isLoading = true
        errorMessage = nil
        do {
            profile = try dataService.fetchProfile()
            settings = try dataService.fetchSettings()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// プロフィールを保存する
    public func saveProfile(displayName: String, bio: String) {
        errorMessage = nil
        do {
            if let profile {
                profile.displayName = displayName
                profile.bio = bio
                try dataService.saveProfile(profile)
            } else {
                let newProfile = CommunityProfile(displayName: displayName, bio: bio)
                try dataService.saveProfile(newProfile)
                profile = newProfile
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 設定を保存し、必要に応じてリマインダーを再設定する
    public func saveSettings() async {
        errorMessage = nil
        do {
            guard let settings else { return }
            try dataService.saveSettings(settings)

            // ゴミ出しリマインダーの再設定
            if settings.isGarbageReminderEnabled {
                await notificationService.removeAllPendingNotifications()
                let schedules = try dataService.fetchGarbageSchedules()
                for schedule in schedules {
                    try await notificationService.scheduleGarbageReminder(
                        garbageType: schedule.garbageType,
                        weekday: schedule.weekday,
                        hour: settings.reminderHour,
                        minute: settings.reminderMinute
                    )
                }
            } else {
                await notificationService.removeAllPendingNotifications()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// オンボーディングを完了する
    public func completeOnboarding() {
        errorMessage = nil
        do {
            guard let settings else { return }
            settings.hasCompletedOnboarding = true
            try dataService.saveSettings(settings)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
