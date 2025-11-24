import Foundation

/// 認証サービスのプロトコル
/// Firebase認証とローカル認証の両方に対応するための抽象化レイヤー
@MainActor
protocol AuthService {
    /// 現在の認証状態
    var isAuthenticated: Bool { get }

    /// 現在のユーザープロファイル
    var currentUser: UserProfile? { get }

    /// 認証状態の変更を監視
    /// - Parameter handler: 認証状態変更時に呼ばれるハンドラ
    func observeAuthState(handler: @escaping (Bool, UserProfile?) -> Void)

    /// 新規ユーザー登録
    /// - Parameters:
    ///   - email: メールアドレス
    ///   - password: パスワード
    ///   - displayName: 表示名
    /// - Throws: 登録に失敗した場合
    func signUp(email: String, password: String, displayName: String) async throws

    /// ログイン
    /// - Parameters:
    ///   - email: メールアドレス
    ///   - password: パスワード
    /// - Throws: ログインに失敗した場合
    func signIn(email: String, password: String) async throws

    /// ログアウト
    /// - Throws: ログアウトに失敗した場合
    func signOut() throws

    /// パスワードリセットメール送信
    /// - Parameter email: メールアドレス
    /// - Throws: 送信に失敗した場合
    func resetPassword(email: String) async throws

    /// ユーザーの家族IDを更新
    /// - Parameter familyId: 家族グループID
    /// - Throws: 更新に失敗した場合
    func updateUserFamilyId(_ familyId: String) async throws
}

/// 認証エラーの種類
enum AuthError: Error, LocalizedError {
    case emailAlreadyInUse
    case invalidEmail
    case weakPassword
    case wrongPassword
    case userNotFound
    case networkError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .emailAlreadyInUse:
            return "このメールアドレスは既に使用されています"
        case .invalidEmail:
            return "無効なメールアドレスです"
        case .weakPassword:
            return "パスワードは6文字以上で設定してください"
        case .wrongPassword:
            return "パスワードが正しくありません"
        case .userNotFound:
            return "ユーザーが見つかりません"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .unknown(let message):
            return "認証エラー: \(message)"
        }
    }
}
