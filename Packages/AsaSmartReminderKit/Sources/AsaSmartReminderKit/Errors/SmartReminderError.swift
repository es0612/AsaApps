import Foundation

// MARK: - アプリエラー

/// AsaSmartReminder全体のエラー定義
public enum SmartReminderError: Error, LocalizedError, Sendable {
    case locationNotFound
    case reminderNotFound
    case saveFailed(String)
    case deleteFailed(String)
    case geofenceLimitReached
    case invalidRadius
    case locationPermissionRequired
    case notificationPermissionRequired
    case monitoringFailed(String)
    case searchFailed(String)

    public var errorDescription: String? {
        switch self {
        case .locationNotFound:
            "場所が見つかりません"
        case .reminderNotFound:
            "リマインダーが見つかりません"
        case .saveFailed(let detail):
            "保存に失敗しました: \(detail)"
        case .deleteFailed(let detail):
            "削除に失敗しました: \(detail)"
        case .geofenceLimitReached:
            "ジオフェンスの上限（20件）に達しています"
        case .invalidRadius:
            "無効な半径です（10m〜5000mの範囲で指定してください）"
        case .locationPermissionRequired:
            "位置情報の権限が必要です"
        case .notificationPermissionRequired:
            "通知の権限が必要です"
        case .monitoringFailed(let detail):
            "監視の開始に失敗しました: \(detail)"
        case .searchFailed(let detail):
            "検索に失敗しました: \(detail)"
        }
    }
}
