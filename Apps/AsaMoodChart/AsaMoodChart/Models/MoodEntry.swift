// AsaApps/Apps/AsaMoodChart/Models/MoodEntry.swift
import Foundation

/// 気分記録エントリ（AsaMoodTracker互換）
struct MoodEntry: Codable, Identifiable {
    var id: UUID
    let date: Date
    let emoji: String
    
    /// イニシャライザ
    init(id: UUID = UUID(), date: Date, emoji: String) {
        self.id = id
        self.date = date
        self.emoji = emoji
    }
    
    /// グラフ表示用に気分を数値に変換
    var moodValue: Double {
        switch emoji {
        case "😢": return 1.0  // 悲しい
        case "😤": return 2.0  // 怒り
        case "😴": return 3.0  // 眠い・疲れ
        case "😊": return 4.0  // 嬉しい
        case "😍": return 5.0  // 最高
        default: return 3.0   // デフォルト値
        }
    }
    
    /// 気分の名称を取得
    var moodName: String {
        switch emoji {
        case "😢": return "悲しい"
        case "😤": return "イライラ"
        case "😴": return "疲れ"
        case "😊": return "良い"
        case "😍": return "最高"
        default: return "普通"
        }
    }
    
    /// 気分の色を取得（グラフ表示用）
    var moodColor: String {
        switch emoji {
        case "😢": return "blue"
        case "😤": return "red"
        case "😴": return "gray"
        case "😊": return "green"
        case "😍": return "purple"
        default: return "gray"
        }
    }
}

// MARK: - MoodEntry拡張機能

extension MoodEntry {
    /// 日付フォーマット（表示用）
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    /// 月日の文字列（グラフのX軸ラベル用）
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    /// 曜日を取得
    var weekdayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

// MARK: - 配列拡張機能（統計・グラフ用）

extension Array where Element == MoodEntry {
    /// 日付でソート（古い順）
    var sortedByDate: [MoodEntry] {
        self.sorted { $0.date < $1.date }
    }
    
    /// 平均気分値を計算
    var averageMoodValue: Double {
        guard !isEmpty else { return 0 }
        let total = self.reduce(0) { $0 + $1.moodValue }
        return total / Double(count)
    }
    
    /// 最頻気分を取得
    var mostFrequentMood: String {
        let counts = Dictionary(grouping: self, by: { $0.emoji })
            .mapValues { $0.count }
        
        return counts.max(by: { $0.value < $1.value })?.key ?? "😊"
    }
    
    /// 期間でフィルタリング
    func entriesInLast(days: Int) -> [MoodEntry] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return self.filter { $0.date >= cutoffDate }
    }
    
    /// 日付別にグループ化（日毎の平均を計算）
    var groupedByDay: [String: Double] {
        let grouped = Dictionary(grouping: self) { entry in
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: entry.date)
        }
        
        return grouped.mapValues { entries in
            entries.reduce(0) { $0 + $1.moodValue } / Double(entries.count)
        }
    }
    
    /// 気分別の件数をカウント
    var moodCounts: [String: Int] {
        Dictionary(grouping: self, by: { $0.moodName })
            .mapValues { $0.count }
    }
}