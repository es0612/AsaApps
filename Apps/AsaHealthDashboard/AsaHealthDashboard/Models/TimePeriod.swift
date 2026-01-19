//
//  TimePeriod.swift
//  AsaHealthDashboard
//
//  データ表示期間の定義
//

import Foundation

/// データ表示期間
enum TimePeriod: String, CaseIterable, Identifiable {
    case day = "日"
    case week = "週"
    case month = "月"

    var id: String { rawValue }

    /// 期間に含まれる日数
    var days: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        }
    }

    /// チャートの日付フォーマット
    var dateFormat: String {
        switch self {
        case .day: return "HH:mm"
        case .week: return "E"
        case .month: return "M/d"
        }
    }

    /// 期間の開始日を取得
    func startDate(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        switch self {
        case .day:
            return calendar.startOfDay(for: date)
        case .week:
            return calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: date)) ?? date
        case .month:
            return calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: date)) ?? date
        }
    }

    /// 期間の終了日を取得
    func endDate(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
    }

    /// 前の期間の開始日を取得（比較用）
    func previousPeriodStartDate(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let currentStart = startDate(from: date)
        return calendar.date(byAdding: .day, value: -days, to: currentStart) ?? date
    }
}
