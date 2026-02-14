import Foundation

// MARK: - CommunityError

/// コミュニティアプリ全体で使用するエラー型
public enum CommunityError: Error, LocalizedError, Sendable {
    case postNotFound
    case eventNotFound
    case communityNotFound
    case profileNotFound
    case shelterNotFound
    case dataServiceError(String)
    case locationPermissionDenied
    case locationUnavailable
    case notificationPermissionDenied
    case contentModerationFailed(String)
    case invalidInput(String)
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .postNotFound:
            return "投稿が見つかりません"
        case .eventNotFound:
            return "イベントが見つかりません"
        case .communityNotFound:
            return "コミュニティが見つかりません"
        case .profileNotFound:
            return "プロフィールが見つかりません"
        case .shelterNotFound:
            return "避難所が見つかりません"
        case .dataServiceError(let message):
            return "データサービスエラー: \(message)"
        case .locationPermissionDenied:
            return "位置情報の利用が許可されていません"
        case .locationUnavailable:
            return "位置情報を取得できません"
        case .notificationPermissionDenied:
            return "通知の送信が許可されていません"
        case .contentModerationFailed(let message):
            return "コンテンツ確認エラー: \(message)"
        case .invalidInput(let message):
            return "入力エラー: \(message)"
        case .networkError(let message):
            return "ネットワークエラー: \(message)"
        }
    }
}
