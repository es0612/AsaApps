//
//  AuthViewModel.swift
//  AsaCrowdsource
//
//  認証状態を管理するViewModel
//

import Foundation
import SwiftUI

/// 認証状態
enum AuthState: Equatable {
    case unknown
    case signedOut
    case signedIn(User)

    var isSignedIn: Bool {
        if case .signedIn = self {
            return true
        }
        return false
    }

    var currentUser: User? {
        if case .signedIn(let user) = self {
            return user
        }
        return nil
    }
}

/// 認証ViewModel
@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var authState: AuthState = .unknown
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let userDefaultsKey = "AsaCrowdsource.CurrentUser"

    // MARK: - Computed Properties

    var isSignedIn: Bool {
        authState.isSignedIn
    }

    var currentUser: User? {
        authState.currentUser
    }

    // MARK: - Initializer

    init() {
        loadPersistedUser()
    }

    // MARK: - Public Methods

    /// メールアドレスとパスワードでサインアップ（モック実装）
    func signUp(email: String, password: String, displayName: String) async {
        guard !email.isEmpty, !password.isEmpty, !displayName.isEmpty else {
            errorMessage = "すべての項目を入力してください"
            return
        }

        guard isValidEmail(email) else {
            errorMessage = "有効なメールアドレスを入力してください"
            return
        }

        guard password.count >= 6 else {
            errorMessage = "パスワードは6文字以上で入力してください"
            return
        }

        isLoading = true
        errorMessage = nil

        // モック遅延（実際のFirebase実装時はここを置き換え）
        try? await Task.sleep(nanoseconds: 500_000_000)

        let user = User(
            id: UUID().uuidString,
            email: email,
            displayName: displayName
        )

        persistUser(user)
        authState = .signedIn(user)
        isLoading = false
    }

    /// メールアドレスとパスワードでサインイン（モック実装）
    func signIn(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "メールアドレスとパスワードを入力してください"
            return
        }

        isLoading = true
        errorMessage = nil

        // モック遅延（実際のFirebase実装時はここを置き換え）
        try? await Task.sleep(nanoseconds: 500_000_000)

        // モック実装：保存されたユーザーを読み込み、なければ新規作成
        if let savedUser = loadUser(email: email) {
            authState = .signedIn(savedUser.withUpdatedLastLogin())
            persistUser(savedUser.withUpdatedLastLogin())
        } else {
            // デモ用：存在しないユーザーでも新規作成
            let user = User(
                id: UUID().uuidString,
                email: email,
                displayName: email.components(separatedBy: "@").first ?? "ユーザー"
            )
            persistUser(user)
            authState = .signedIn(user)
        }

        isLoading = false
    }

    /// サインアウト
    func signOut() {
        clearPersistedUser()
        authState = .signedOut
    }

    /// ゲストモードでサインイン
    func signInAsGuest() {
        let guestUser = User(
            id: "guest_\(UUID().uuidString)",
            email: "",
            displayName: "ゲスト"
        )
        authState = .signedIn(guestUser)
    }

    /// 表示名を更新
    func updateDisplayName(_ name: String) {
        guard var user = currentUser else { return }
        user.displayName = name
        persistUser(user)
        authState = .signedIn(user)
    }

    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Methods

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func loadPersistedUser() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            authState = .signedIn(user)
        } else {
            authState = .signedOut
        }
    }

    private func persistUser(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    private func clearPersistedUser() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    private func loadUser(email: String) -> User? {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: data),
           user.email == email {
            return user
        }
        return nil
    }
}
