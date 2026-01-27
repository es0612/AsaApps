import Foundation

// MARK: - AuthError

enum AuthError: Error, LocalizedError {
    case signInFailed(String)
    case signUpFailed(String)
    case signOutFailed(String)
    case userNotFound
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .signInFailed(let message): return "ログイン失敗: \(message)"
        case .signUpFailed(let message): return "登録失敗: \(message)"
        case .signOutFailed(let message): return "ログアウト失敗: \(message)"
        case .userNotFound: return "ユーザーが見つかりません"
        case .invalidCredentials: return "メールアドレスまたはパスワードが正しくありません"
        case .emailAlreadyInUse: return "このメールアドレスは既に使用されています"
        case .weakPassword: return "パスワードは6文字以上で設定してください"
        case .networkError: return "ネットワークエラーが発生しました"
        case .unknown(let error): return "エラー: \(error.localizedDescription)"
        }
    }
}

// MARK: - UserProfile

struct UserProfile: Codable, Identifiable, Sendable {
    var id: String
    var email: String
    var displayName: String?
    var photoURL: String?
    var createdAt: Date
    var lastSignInAt: Date?
    var deviceIds: [String]

    init(
        id: String,
        email: String,
        displayName: String? = nil,
        photoURL: String? = nil,
        createdAt: Date = Date(),
        lastSignInAt: Date? = nil,
        deviceIds: [String] = []
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.lastSignInAt = lastSignInAt
        self.deviceIds = deviceIds
    }
}

// MARK: - AuthServiceProtocol

protocol AuthServiceProtocol: AnyObject, Sendable {
    // MARK: - Properties

    var isAuthenticated: Bool { get }
    var currentUser: UserProfile? { get }
    var currentUserId: String? { get }

    // MARK: - Authentication

    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String, displayName: String?) async throws
    func signOut() async throws

    // MARK: - User Profile

    func fetchUserProfile() async throws -> UserProfile?
    func updateUserProfile(displayName: String?, photoURL: String?) async throws

    // MARK: - Device Management

    func registerDevice(deviceId: String) async throws
    func unregisterDevice(deviceId: String) async throws

    // MARK: - Password

    func sendPasswordResetEmail(to email: String) async throws

    // MARK: - Observation

    func observeAuthState(_ handler: @escaping (UserProfile?) -> Void)
}

// MARK: - Default Implementation

extension AuthServiceProtocol {
    var currentUserId: String? {
        currentUser?.id
    }

    func updateUserProfile(displayName: String? = nil, photoURL: String? = nil) async throws {
        // Default implementation does nothing
    }

    func registerDevice(deviceId: String) async throws {
        // Default implementation does nothing
    }

    func unregisterDevice(deviceId: String) async throws {
        // Default implementation does nothing
    }
}
