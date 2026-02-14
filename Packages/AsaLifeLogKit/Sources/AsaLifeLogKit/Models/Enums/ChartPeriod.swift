import Foundation

// MARK: - ChartPeriod

/// チャート表示期間
public enum ChartPeriod: String, CaseIterable, Codable, Sendable {
    case week
    case month
    case threeMonths
    case year

    /// 日本語表示名
    public var displayName: String {
        switch self {
        case .week: return "1週間"
        case .month: return "1ヶ月"
        case .threeMonths: return "3ヶ月"
        case .year: return "1年"
        }
    }

    /// 期間の日数
    public var dayCount: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        }
    }
}
