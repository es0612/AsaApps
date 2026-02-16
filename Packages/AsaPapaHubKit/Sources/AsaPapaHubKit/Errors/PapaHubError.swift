import Foundation

// MARK: - PapaHub エラー

public enum PapaHubError: Error, LocalizedError, Sendable {
    case dataNotFound
    case saveFailed(String)
    case fetchFailed(String)
    case invalidData(String)
    case aiNotAvailable
    case aiGenerationFailed(String)
    case routineAlreadyStarted
    case notificationPermissionDenied
    case widgetUpdateFailed(String)

    public var errorDescription: String? {
        switch self {
        case .dataNotFound:
            "データが見つかりませんでした"
        case .saveFailed(let detail):
            "保存に失敗しました: \(detail)"
        case .fetchFailed(let detail):
            "データ取得に失敗しました: \(detail)"
        case .invalidData(let detail):
            "無効なデータです: \(detail)"
        case .aiNotAvailable:
            "AI機能は現在利用できません"
        case .aiGenerationFailed(let detail):
            "AI生成に失敗しました: \(detail)"
        case .routineAlreadyStarted:
            "ルーティンは既に開始されています"
        case .notificationPermissionDenied:
            "通知の権限が拒否されました"
        case .widgetUpdateFailed(let detail):
            "ウィジェット更新に失敗しました: \(detail)"
        }
    }
}
