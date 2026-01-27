//
//  SettingsViewModel.swift
//  AsaLiveChat
//
//  設定画面のViewModel
//

import Foundation

/// 設定画面を管理するViewModel
///
/// ユーザー名、アバター、通知設定などを管理します。
@MainActor
@Observable
final class SettingsViewModel {
    // MARK: - Dependencies

    private let dataService: ChatDataService

    // MARK: - State

    /// ユーザー設定
    private(set) var settings: UserSettings

    /// 保存成功メッセージ
    private(set) var successMessage: String?

    /// エラーメッセージ
    private(set) var errorMessage: String?

    // MARK: - UI State

    /// アバター選択シート表示フラグ
    var showingAvatarPicker = false

    /// サーバーURL編集シート表示フラグ
    var showingServerEditor = false

    /// カスタムサーバーURL入力
    var customServerURL = ""

    // MARK: - Computed Properties

    /// 現在のユーザー名
    var userName: String {
        get { settings.userName }
        set {
            settings.userName = newValue
            saveSettings()
        }
    }

    /// 現在のアバター絵文字
    var avatarEmoji: String {
        get { settings.avatarEmoji }
        set {
            settings.avatarEmoji = newValue
            saveSettings()
        }
    }

    /// 通知有効フラグ
    var notificationsEnabled: Bool {
        get { settings.notificationsEnabled }
        set {
            settings.notificationsEnabled = newValue
            saveSettings()
        }
    }

    /// サウンド有効フラグ
    var soundEnabled: Bool {
        get { settings.soundEnabled }
        set {
            settings.soundEnabled = newValue
            saveSettings()
        }
    }

    /// バイブレーション有効フラグ
    var vibrationEnabled: Bool {
        get { settings.vibrationEnabled }
        set {
            settings.vibrationEnabled = newValue
            saveSettings()
        }
    }

    /// 入力中表示の送信フラグ
    var sendTypingIndicator: Bool {
        get { settings.sendTypingIndicator }
        set {
            settings.sendTypingIndicator = newValue
            saveSettings()
        }
    }

    /// 既読表示の送信フラグ
    var sendReadReceipts: Bool {
        get { settings.sendReadReceipts }
        set {
            settings.sendReadReceipts = newValue
            saveSettings()
        }
    }

    /// サーバーURL
    var serverURL: String {
        get { settings.serverURL }
        set {
            settings.serverURL = newValue
            saveSettings()
        }
    }

    /// サーバー名（表示用）
    var serverDisplayName: String {
        for server in UserSettings.availableServers {
            if server.url == settings.serverURL {
                return server.name
            }
        }
        return "カスタム"
    }

    /// ユーザーID
    var userId: String {
        settings.userId
    }

    /// ChatUser表現
    var currentUser: ChatUser {
        settings.asChatUser
    }

    // MARK: - Initialization

    init(dataService: ChatDataService) {
        self.dataService = dataService
        self.settings = dataService.getOrCreateUserSettings()
    }

    // MARK: - Methods

    /// 設定を保存
    func saveSettings() {
        dataService.updateUserSettings(settings)
    }

    /// アバターを選択
    func selectAvatar(_ emoji: String) {
        avatarEmoji = emoji
        showingAvatarPicker = false
    }

    /// サーバーを選択
    func selectServer(_ server: (name: String, url: String)) {
        if server.url.isEmpty {
            // カスタムサーバー
            customServerURL = serverURL
            showingServerEditor = true
        } else {
            serverURL = server.url
        }
    }

    /// カスタムサーバーURLを保存
    func saveCustomServerURL() {
        let trimmed = customServerURL.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            errorMessage = "URLを入力してください"
            return
        }

        guard trimmed.hasPrefix("ws://") || trimmed.hasPrefix("wss://") else {
            errorMessage = "ws:// または wss:// で始まるURLを入力してください"
            return
        }

        serverURL = trimmed
        showingServerEditor = false
        successMessage = "サーバーURLを更新しました"

        // 3秒後にメッセージをクリア
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            successMessage = nil
        }
    }

    /// 設定をリセット
    func resetSettings() {
        let newSettings = UserSettings(userId: settings.userId)
        settings.userName = newSettings.userName
        settings.avatarEmoji = newSettings.avatarEmoji
        settings.notificationsEnabled = newSettings.notificationsEnabled
        settings.soundEnabled = newSettings.soundEnabled
        settings.vibrationEnabled = newSettings.vibrationEnabled
        settings.sendTypingIndicator = newSettings.sendTypingIndicator
        settings.sendReadReceipts = newSettings.sendReadReceipts
        settings.serverURL = newSettings.serverURL

        saveSettings()
        successMessage = "設定をリセットしました"

        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            successMessage = nil
        }
    }

    /// メッセージをクリア
    func clearMessages() {
        successMessage = nil
        errorMessage = nil
    }
}
