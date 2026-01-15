import Foundation
import AuthenticationServices

// MARK: - Auth Error

enum AuthError: Error, LocalizedError {
    case signInFailed(String)
    case signOutFailed(String)
    case userNotFound
    case invalidCredential
    case networkError
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .signInFailed(let message):
            return "サインインに失敗しました: \(message)"
        case .signOutFailed(let message):
            return "サインアウトに失敗しました: \(message)"
        case .userNotFound:
            return "ユーザーが見つかりません"
        case .invalidCredential:
            return "認証情報が無効です"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .unknown(let error):
            return "エラーが発生しました: \(error.localizedDescription)"
        }
    }
}

// MARK: - Auth Service Protocol

/// 認証サービスのプロトコル
protocol AuthService: Sendable {
    /// 認証状態
    var isAuthenticated: Bool { get }

    /// 現在のユーザー
    var currentUser: User? { get }

    /// Apple Sign-Inでサインイン
    func signInWithApple(authorization: ASAuthorization) async throws

    /// サインアウト
    func signOut() throws

    /// ユーザープロファイルを更新
    func updateUserProfile(displayName: String?, photoURL: String?) async throws

    /// FCMトークンを更新
    func updateFCMToken(_ token: String) async throws

    /// 認証状態の変更をリスニング
    func addAuthStateListener(_ handler: @escaping (User?) -> Void) -> Any
}
