import Foundation
import SwiftData

@Model
final class HabitRecord {
    // MARK: - Properties

    var id: UUID
    var completedAt: Date
    var note: String
    var duration: TimeInterval? // 活動時間（秒）
    var mood: RecordMood?
    var createdAt: Date

    // リレーション
    var habit: Habit?

    // MARK: - Initialization

    init(
        habit: Habit,
        completedAt: Date = Date(),
        note: String = "",
        duration: TimeInterval? = nil,
        mood: RecordMood? = nil
    ) {
        self.id = UUID()
        self.habit = habit
        self.completedAt = completedAt
        self.note = note
        self.duration = duration
        self.mood = mood
        self.createdAt = Date()
    }
}

// MARK: - Supporting Types

enum RecordMood: String, CaseIterable, Codable {
    case excellent = "最高"
    case good = "良い"
    case normal = "普通"
    case tired = "疲れた"
    case difficult = "きつかった"

    var emoji: String {
        switch self {
        case .excellent: return "😍"
        case .good: return "😊"
        case .normal: return "😐"
        case .tired: return "😴"
        case .difficult: return "😓"
        }
    }

    var value: Double {
        switch self {
        case .excellent: return 5.0
        case .good: return 4.0
        case .normal: return 3.0
        case .tired: return 2.0
        case .difficult: return 1.0
        }
    }
}

// MARK: - Computed Properties

extension HabitRecord {
    var formattedDuration: String? {
        guard let duration = duration else { return nil }

        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)時間 \(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: completedAt)
    }

    var weekdayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: completedAt)
    }
}

// MARK: - Helper Extensions

extension Array where Element == HabitRecord {
    // 日付でグループ化
    func groupedByDate() -> [Date: [HabitRecord]] {
        let calendar = Calendar.current
        var grouped: [Date: [HabitRecord]] = [:]

        for record in self {
            let startOfDay = calendar.startOfDay(for: record.completedAt)
            if grouped[startOfDay] == nil {
                grouped[startOfDay] = []
            }
            grouped[startOfDay]?.append(record)
        }

        return grouped
    }

    // 週でグループ化
    func groupedByWeek() -> [Date: [HabitRecord]] {
        let calendar = Calendar.current
        var grouped: [Date: [HabitRecord]] = [:]

        for record in self {
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: record.completedAt)?.start else {
                continue
            }
            if grouped[weekStart] == nil {
                grouped[weekStart] = []
            }
            grouped[weekStart]?.append(record)
        }

        return grouped
    }

    // 月でグループ化
    func groupedByMonth() -> [Date: [HabitRecord]] {
        let calendar = Calendar.current
        var grouped: [Date: [HabitRecord]] = [:]

        for record in self {
            guard let monthStart = calendar.dateInterval(of: .month, for: record.completedAt)?.start else {
                continue
            }
            if grouped[monthStart] == nil {
                grouped[monthStart] = []
            }
            grouped[monthStart]?.append(record)
        }

        return grouped
    }
}