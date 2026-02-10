import Foundation

// MARK: - FinancePlannerError

/// 金融プランナーアプリ全体で使用するエラー型
public enum FinancePlannerError: Error, LocalizedError, Sendable {
    case invalidAmount
    case invalidRate
    case invalidPeriod
    case goalNotFound
    case planNotFound
    case assetNotFound
    case dataServiceError(String)
    case authenticationFailed
    case calculationError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "金額が無効です"
        case .invalidRate:
            return "利率が無効です"
        case .invalidPeriod:
            return "期間が無効です"
        case .goalNotFound:
            return "目標が見つかりません"
        case .planNotFound:
            return "プランが見つかりません"
        case .assetNotFound:
            return "資産が見つかりません"
        case .dataServiceError(let message):
            return "データサービスエラー: \(message)"
        case .authenticationFailed:
            return "認証に失敗しました"
        case .calculationError(let message):
            return "計算エラー: \(message)"
        }
    }
}
