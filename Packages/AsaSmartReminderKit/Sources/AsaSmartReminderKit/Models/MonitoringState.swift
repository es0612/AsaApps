import Foundation

// MARK: - 監視状態

/// ジオフェンス監視の現在状態を表す
public enum MonitoringState: Sendable, Equatable {
    /// 監視していない
    case idle
    /// 監視準備中
    case starting
    /// 監視中（アクティブなリージョン数）
    case monitoring(activeCount: Int)
    /// エラー発生
    case error(MonitoringError)

    public var isMonitoring: Bool {
        if case .monitoring = self { return true }
        return false
    }

    public var activeCount: Int {
        if case .monitoring(let count) = self { return count }
        return 0
    }

    public var displayText: String {
        switch self {
        case .idle: "停止中"
        case .starting: "開始中..."
        case .monitoring(let count): "監視中（\(count)/20）"
        case .error(let error): "エラー: \(error.displayText)"
        }
    }
}

// MARK: - 監視エラー

public enum MonitoringError: Sendable, Equatable {
    case locationPermissionDenied
    case notificationPermissionDenied
    case monitorCreationFailed
    case locationServicesDisabled
    case unknown(String)

    public var displayText: String {
        switch self {
        case .locationPermissionDenied: "位置情報の権限がありません"
        case .notificationPermissionDenied: "通知の権限がありません"
        case .monitorCreationFailed: "監視の開始に失敗しました"
        case .locationServicesDisabled: "位置情報サービスが無効です"
        case .unknown(let message): message
        }
    }
}
