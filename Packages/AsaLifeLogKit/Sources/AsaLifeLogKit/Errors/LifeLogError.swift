import Foundation

// MARK: - LifeLogError

/// ライフログ関連のエラー
public enum LifeLogError: Error, LocalizedError, Sendable {
    /// データが見つからない
    case dataNotFound
    /// 保存に失敗した
    case saveFailed(underlying: any Error)
    /// 位置情報が利用できない
    case locationNotAvailable
    /// 写真ライブラリへのアクセスが拒否された
    case photoAccessDenied
    /// アクティビティ認識が利用できない
    case activityNotAvailable
    /// エクスポートに失敗した
    case exportFailed
    /// 無効なエントリー
    case invalidEntry(reason: String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .dataNotFound:
            return "データが見つかりませんでした"
        case .saveFailed(let underlying):
            return "保存に失敗しました: \(underlying.localizedDescription)"
        case .locationNotAvailable:
            return "位置情報が利用できません"
        case .photoAccessDenied:
            return "写真ライブラリへのアクセスが拒否されました"
        case .activityNotAvailable:
            return "アクティビティ認識が利用できません"
        case .exportFailed:
            return "データのエクスポートに失敗しました"
        case .invalidEntry(let reason):
            return "無効なエントリーです: \(reason)"
        }
    }
}
