//
//  GratitudeModel.swift
//  AsaGratitude
//  
//  Created on 2025/07/02
//

import Foundation

struct GratitudeEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let content: String
    let category: GratitudeCategory
    let moodLevel: GratitudeMood
    let createdAt: Date
    
    init(id: UUID = UUID(), date: Date = Date(), content: String, category: GratitudeCategory = .general, moodLevel: GratitudeMood = .grateful, createdAt: Date = Date()) {
        self.id = id
        self.date = date
        self.content = content
        self.category = category
        self.moodLevel = moodLevel
        self.createdAt = createdAt
    }
    
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: createdAt)
    }
    
    var shortContent: String {
        if content.count > 50 {
            return String(content.prefix(50)) + "..."
        }
        return content
    }
}

enum GratitudeCategory: String, CaseIterable, Codable {
    case family = "family"
    case work = "work"
    case health = "health"
    case nature = "nature"
    case friends = "friends"
    case food = "food"
    case learning = "learning"
    case achievement = "achievement"
    case kindness = "kindness"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .family: return "家族"
        case .work: return "仕事"
        case .health: return "健康"
        case .nature: return "自然"
        case .friends: return "友人"
        case .food: return "食事"
        case .learning: return "学び"
        case .achievement: return "成果"
        case .kindness: return "親切"
        case .general: return "その他"
        }
    }
    
    var emoji: String {
        switch self {
        case .family: return "👨‍👩‍👧‍👦"
        case .work: return "💼"
        case .health: return "💚"
        case .nature: return "🌿"
        case .friends: return "👫"
        case .food: return "🍽️"
        case .learning: return "📚"
        case .achievement: return "🏆"
        case .kindness: return "🤝"
        case .general: return "✨"
        }
    }
    
    var color: String {
        switch self {
        case .family: return "AsaCoffeeBrown"
        case .work: return "AsaMutedSage"
        case .health: return "AsaSoftCream"
        case .nature: return "AsaMutedSage"
        case .friends: return "AsaCoffeeBrown"
        case .food: return "AsaMocha"
        case .learning: return "AsaMutedSage"
        case .achievement: return "AsaCoffeeBrown"
        case .kindness: return "AsaSoftCream"
        case .general: return "AsaMutedSage"
        }
    }
}

enum GratitudeMood: Int, CaseIterable, Codable {
    case grateful = 3
    case veryGrateful = 4
    case blessed = 5
    
    var displayName: String {
        switch self {
        case .grateful: return "感謝している"
        case .veryGrateful: return "とても感謝している"
        case .blessed: return "本当に幸せ"
        }
    }
    
    var emoji: String {
        switch self {
        case .grateful: return "😊"
        case .veryGrateful: return "🥰"
        case .blessed: return "😇"
        }
    }
    
    var color: String {
        switch self {
        case .grateful: return "AsaMutedSage"
        case .veryGrateful: return "AsaCoffeeBrown"
        case .blessed: return "AsaMocha"
        }
    }
    
    var stars: String {
        return String(repeating: "⭐", count: self.rawValue)
    }
}

struct GratitudeQuote {
    let text: String
    let author: String?
    
    static let inspirationalQuotes: [GratitudeQuote] = [
        GratitudeQuote(text: "感謝は、あなたが今持っているものを十分にする。", author: "メロディー・ビーティー"),
        GratitudeQuote(text: "感謝の心は幸福の源である。", author: "ジョン・F・ケネディ"),
        GratitudeQuote(text: "小さなことにも感謝しよう。きっと大きな幸せが見つかるから。", author: nil),
        GratitudeQuote(text: "一日の終わりに、今日の良かったことを三つ思い出そう。", author: nil),
        GratitudeQuote(text: "感謝は最も記憶に残る人間の感情である。", author: "マーカス・キケロ"),
        GratitudeQuote(text: "感謝の気持ちがあれば、人生のすべてが恵みに変わる。", author: nil),
        GratitudeQuote(text: "毎日を感謝の気持ちで始めよう。", author: nil),
        GratitudeQuote(text: "感謝は心の記憶である。", author: "ジャン・バティスト・マシウ"),
        GratitudeQuote(text: "今この瞬間に感謝しよう。それが幸せへの第一歩。", author: nil),
        GratitudeQuote(text: "感謝の心を持つ人は、どんな状況でも喜びを見つけられる。", author: nil)
    ]
    
    static func randomQuote() -> GratitudeQuote {
        return inspirationalQuotes.randomElement() ?? inspirationalQuotes[0]
    }
}

struct GratitudeStats {
    let totalEntries: Int
    let thisWeekEntries: Int
    let thisMonthEntries: Int
    let currentStreak: Int
    let longestStreak: Int
    let averageEntriesPerDay: Double
    let mostCommonCategory: GratitudeCategory?
    let mostCommonMood: GratitudeMood?
    
    init(entries: [GratitudeEntry]) {
        self.totalEntries = entries.count
        
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        self.thisWeekEntries = entries.filter { $0.date >= weekStart && $0.date <= now }.count
        self.thisMonthEntries = entries.filter { $0.date >= monthStart && $0.date <= now }.count
        
        // 連続記録日数の計算
        let sortedEntries = entries.sorted { $0.date > $1.date }
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        
        var currentDate = calendar.startOfDay(for: now)
        var hasEntryToday = false
        
        for entry in sortedEntries {
            let entryDate = calendar.startOfDay(for: entry.date)
            
            if entryDate == currentDate {
                if !hasEntryToday {
                    tempStreak += 1
                    hasEntryToday = true
                }
            } else if entryDate == calendar.date(byAdding: .day, value: -1, to: currentDate) {
                currentDate = entryDate
                tempStreak += 1
                hasEntryToday = true
            } else {
                longestStreak = max(longestStreak, tempStreak)
                if entryDate == calendar.startOfDay(for: now) {
                    currentStreak = tempStreak
                }
                tempStreak = 1
                currentDate = entryDate
                hasEntryToday = true
            }
        }
        
        self.currentStreak = tempStreak
        self.longestStreak = max(longestStreak, tempStreak)
        
        // 平均エントリー数
        if !entries.isEmpty {
            let firstEntry = entries.min(by: { $0.date < $1.date })?.date ?? now
            let daysSinceFirst = calendar.dateComponents([.day], from: firstEntry, to: now).day ?? 1
            self.averageEntriesPerDay = Double(totalEntries) / Double(max(daysSinceFirst, 1))
        } else {
            self.averageEntriesPerDay = 0
        }
        
        // 最も多いカテゴリー
        let categoryCounts = Dictionary(grouping: entries, by: { $0.category })
            .mapValues { $0.count }
        self.mostCommonCategory = categoryCounts.max(by: { $0.value < $1.value })?.key
        
        // 最も多い気分
        let moodCounts = Dictionary(grouping: entries, by: { $0.moodLevel })
            .mapValues { $0.count }
        self.mostCommonMood = moodCounts.max(by: { $0.value < $1.value })?.key
    }
}