import Foundation

/// 時間範囲 - チャート表示や分析期間の指定に使用
enum TimeRange: String, Codable, CaseIterable, Sendable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"
    case threeYears = "3Y"
    case fiveYears = "5Y"
    case all = "ALL"

    var displayName: String {
        switch self {
        case .day: return "1日"
        case .week: return "1週間"
        case .month: return "1ヶ月"
        case .threeMonths: return "3ヶ月"
        case .sixMonths: return "6ヶ月"
        case .year: return "1年"
        case .threeYears: return "3年"
        case .fiveYears: return "5年"
        case .all: return "全期間"
        }
    }

    /// 該当期間の開始日を計算
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .day:
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .threeYears:
            return calendar.date(byAdding: .year, value: -3, to: now) ?? now
        case .fiveYears:
            return calendar.date(byAdding: .year, value: -5, to: now) ?? now
        case .all:
            return Date.distantPast
        }
    }

    /// チャート表示用の日数
    var daysCount: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .year: return 365
        case .threeYears: return 365 * 3
        case .fiveYears: return 365 * 5
        case .all: return 365 * 10
        }
    }
}
