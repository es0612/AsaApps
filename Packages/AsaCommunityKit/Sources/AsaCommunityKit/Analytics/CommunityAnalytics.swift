import Foundation

// MARK: - CommunityAnalytics

/// Charts 用の集計ユーティリティ
///
/// 投稿・イベント・安全レポートのデータを静的メソッドで集計し、
/// SwiftUI Charts に渡せる形式に変換する。
public struct CommunityAnalytics: Sendable {
    // MARK: - Post Analytics

    /// カテゴリ別の投稿数を集計する
    public static func postCountByCategory(
        posts: [CommunityPost]
    ) -> [(category: PostCategory, count: Int)] {
        var counts: [PostCategory: Int] = [:]
        for post in posts {
            counts[post.category, default: 0] += 1
        }
        return PostCategory.allCases.compactMap { category in
            guard let count = counts[category], count > 0 else { return nil }
            return (category: category, count: count)
        }
    }

    /// 週別の投稿数を集計する
    public static func postCountByWeek(
        posts: [CommunityPost],
        weeks: Int = 8
    ) -> [(week: Date, count: Int)] {
        let calendar = Calendar.current
        let now = Date()

        // 各週の開始日を計算
        var weekStarts: [Date] = []
        for i in 0..<weeks {
            if let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: now) {
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: weekStart)?.start ?? weekStart
                weekStarts.append(startOfWeek)
            }
        }
        weekStarts.reverse()

        return weekStarts.map { weekStart in
            guard let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else {
                return (week: weekStart, count: 0)
            }
            let count = posts.filter { $0.createdAt >= weekStart && $0.createdAt < weekEnd }.count
            return (week: weekStart, count: count)
        }
    }

    // MARK: - Event Analytics

    /// イベント参加率を計算する（出席者数 / 定員の平均）
    public static func eventAttendanceRate(
        events: [CommunityEvent]
    ) -> Double {
        let eventsWithCapacity = events.filter { $0.maxParticipants > 0 }
        guard !eventsWithCapacity.isEmpty else { return 0.0 }

        let totalRate = eventsWithCapacity.reduce(0.0) { sum, event in
            sum + Double(event.attendeeCount) / Double(event.maxParticipants)
        }
        return totalRate / Double(eventsWithCapacity.count)
    }

    // MARK: - Safety Analytics

    /// 警戒レベル別の安全レポート数を集計する
    public static func safetyReportsByLevel(
        reports: [SafetyReport]
    ) -> [(level: SafetyAlertLevel, count: Int)] {
        var counts: [SafetyAlertLevel: Int] = [:]
        for report in reports {
            counts[report.alertLevel, default: 0] += 1
        }
        return SafetyAlertLevel.allCases.compactMap { level in
            guard let count = counts[level], count > 0 else { return nil }
            return (level: level, count: count)
        }
    }
}
