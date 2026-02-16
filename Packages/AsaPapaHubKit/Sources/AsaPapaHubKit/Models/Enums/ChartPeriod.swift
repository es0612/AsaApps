import Foundation

// MARK: - チャート期間

public enum ChartPeriod: String, CaseIterable, Sendable, Codable {
    case day
    case week
    case month

    public var displayName: String {
        switch self {
        case .day: "日"
        case .week: "週"
        case .month: "月"
        }
    }

    public var calendarComponent: Calendar.Component {
        switch self {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        }
    }

    public var dayCount: Int {
        switch self {
        case .day: 1
        case .week: 7
        case .month: 30
        }
    }
}
