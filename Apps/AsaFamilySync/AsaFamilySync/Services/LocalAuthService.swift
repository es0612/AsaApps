import Foundation
import Combine

/// UserDefaultsベースのローカル認証サービス
/// シミュレータでの動作確認用（実際のパスワード検証なし）
@MainActor
class LocalAuthService: AuthService {
    // MARK: - Properties

    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: UserProfile?

    private let userDefaultsKey = "AsaFamilySync.LocalAuth"
    private let currentUserKey = "AsaFamilySync.CurrentUser"
    private var authStateHandler: ((Bool, UserProfile?) -> Void)?

    // MARK: - Initialization

    init() {
        loadAuthState()
    }

    // MARK: - AuthService Protocol

    func observeAuthState(handler: @escaping (Bool, UserProfile?) -> Void) {
        self.authStateHandler = handler
        // 初回の状態を通知
        handler(isAuthenticated, currentUser)
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        // バリデーション
        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }

        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }

        guard !displayName.isEmpty else {
            throw AuthError.unknown("表示名を入力してください")
        }

        // 既存ユーザーチェック（簡易版）
        if let existingUsers = loadAllUsers(), existingUsers.contains(where: { $0.email == email }) {
            throw AuthError.emailAlreadyInUse
        }

        // ユーザープロファイルを作成
        let uid = UUID().uuidString
        let profile = UserProfile(
            uid: uid,
            email: email,
            displayName: displayName,
            createdAt: Date(),
            updatedAt: Date()
        )

        // 保存
        try saveUser(profile, password: password)
        currentUser = profile
        isAuthenticated = true

        // 認証状態変更を通知
        authStateHandler?(true, profile)
    }

    func signIn(email: String, password: String) async throws {
        // バリデーション
        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }

        guard !password.isEmpty else {
            throw AuthError.wrongPassword
        }

        // ユーザーを検索
        guard let users = loadAllUsers(),
              let user = users.first(where: { $0.email == email }) else {
            throw AuthError.userNotFound
        }

        // パスワード検証（簡易版：実際には保存されたパスワードと比較）
        guard let storedPassword = loadPassword(for: user.uid),
              storedPassword == password else {
            throw AuthError.wrongPassword
        }

        currentUser = user
        isAuthenticated = true

        // 認証状態をUserDefaultsに保存
        saveAuthState()

        // 認証状態変更を通知
        authStateHandler?(true, user)
    }

    func signOut() throws {
        currentUser = nil
        isAuthenticated = false

        // 認証状態をクリア
        UserDefaults.standard.removeObject(forKey: currentUserKey)

        // 認証状態変更を通知
        authStateHandler?(false, nil)
    }

    func resetPassword(email: String) async throws {
        // ローカル版では実装なし（メール送信不可）
        // 成功したふりをする
        print("パスワードリセットメール送信（シミュレート）: \(email)")
    }

    func updateUserFamilyId(_ familyId: String) async throws {
        guard var user = currentUser else {
            throw AuthError.userNotFound
        }

        user.familyId = familyId
        if !user.familyIds.contains(familyId) {
            user.familyIds.append(familyId)
        }
        user.updatedAt = Date()

        // 更新されたプロファイルを保存
        let password = loadPassword(for: user.uid) ?? ""
        try saveUser(user, password: password)

        currentUser = user

        // 認証状態変更を通知（ユーザー情報更新）
        authStateHandler?(true, user)
    }

    // MARK: - Private Methods

    private func loadAuthState() {
        if let data = UserDefaults.standard.data(forKey: currentUserKey),
           let user = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentUser = user
            isAuthenticated = true
        }
    }

    private func saveAuthState() {
        if let user = currentUser,
           let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: currentUserKey)
        }
    }

    private func saveUser(_ user: UserProfile, password: String) throws {
        var users = loadAllUsers() ?? []

        // 既存ユーザーを更新または新規追加
        if let index = users.firstIndex(where: { $0.uid == user.uid }) {
            users[index] = user
        } else {
            users.append(user)
        }

        // ユーザーリストを保存
        let data = try JSONEncoder().encode(users)
        UserDefaults.standard.set(data, forKey: userDefaultsKey)

        // パスワードを保存（簡易版：実際にはKeychain使用を推奨）
        UserDefaults.standard.set(password, forKey: "password_\(user.uid)")

        // 現在のユーザーを保存
        let userData = try JSONEncoder().encode(user)
        UserDefaults.standard.set(userData, forKey: currentUserKey)
    }

    private func loadAllUsers() -> [UserProfile]? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let users = try? JSONDecoder().decode([UserProfile].self, from: data) else {
            return nil
        }
        return users
    }

    private func loadPassword(for uid: String) -> String? {
        return UserDefaults.standard.string(forKey: "password_\(uid)")
    }
}
