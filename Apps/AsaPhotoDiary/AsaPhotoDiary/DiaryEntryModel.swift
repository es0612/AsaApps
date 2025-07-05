//
//  DiaryEntryModel.swift
//  AsaPhotoDiary
//  
//  Created on 2025/07/05
//

import Foundation
import SwiftUI

// MARK: - DiaryEntry Extension
extension DiaryEntry {
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date ?? Date())
    }
    
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: createdAt ?? Date())
    }
    
    var shortContent: String {
        guard let content = content else { return "" }
        if content.count > 50 {
            return String(content.prefix(50)) + "..."
        }
        return content
    }
    
    var categoryEnum: DiaryCategory {
        DiaryCategory(rawValue: category ?? "日常") ?? .daily
    }
    
    var moodEnum: DiaryMood {
        DiaryMood(rawValue: mood ?? "普通") ?? .normal
    }
    
    var image: UIImage? {
        if let imageData = imageData {
            return UIImage(data: imageData)
        }
        return nil
    }
}

// MARK: - DiaryCategory
enum DiaryCategory: String, CaseIterable, Codable {
    case daily = "日常"
    case family = "家族"
    case work = "仕事"
    case travel = "旅行"
    case food = "食事"
    case health = "健康"
    case learning = "学び"
    case hobby = "趣味"
    case nature = "自然"
    case friends = "友人"
    
    var displayName: String {
        return self.rawValue
    }
    
    var emoji: String {
        switch self {
        case .daily: return "📅"
        case .family: return "👨‍👩‍👧‍👦"
        case .work: return "💼"
        case .travel: return "✈️"
        case .food: return "🍽️"
        case .health: return "💚"
        case .learning: return "📚"
        case .hobby: return "🎨"
        case .nature: return "🌿"
        case .friends: return "👫"
        }
    }
    
    var color: String {
        switch self {
        case .daily: return "AsaMutedSage"
        case .family: return "AsaCoffeeBrown"
        case .work: return "AsaDarkSlate"
        case .travel: return "AsaSoftCream"
        case .food: return "AsaMocha"
        case .health: return "AsaMutedSage"
        case .learning: return "AsaCoffeeBrown"
        case .hobby: return "AsaSoftCream"
        case .nature: return "AsaMutedSage"
        case .friends: return "AsaCoffeeBrown"
        }
    }
}

// MARK: - DiaryMood
enum DiaryMood: String, CaseIterable, Codable {
    case veryBad = "とても悪い"
    case bad = "悪い"
    case normal = "普通"
    case good = "良い"
    case veryGood = "とても良い"
    case excellent = "最高"
    case happy = "幸せ"
    case satisfied = "満足"
    case grateful = "感謝"
    case excited = "興奮"
    
    var displayName: String {
        return self.rawValue
    }
    
    var emoji: String {
        switch self {
        case .veryBad: return "😢"
        case .bad: return "😔"
        case .normal: return "😐"
        case .good: return "😊"
        case .veryGood: return "😄"
        case .excellent: return "🤩"
        case .happy: return "😊"
        case .satisfied: return "😌"
        case .grateful: return "🙏"
        case .excited: return "😆"
        }
    }
    
    var color: String {
        switch self {
        case .veryBad, .bad: return "AsaDarkSlate"
        case .normal: return "AsaMutedSage"
        case .good, .happy, .satisfied: return "AsaCoffeeBrown"
        case .veryGood, .excellent, .grateful, .excited: return "AsaMocha"
        }
    }
    
    var rating: Int {
        switch self {
        case .veryBad: return 1
        case .bad: return 2
        case .normal: return 3
        case .good, .happy, .satisfied: return 4
        case .veryGood, .excellent, .grateful, .excited: return 5
        }
    }
}

// MARK: - DiaryStats
struct DiaryStats {
    let totalEntries: Int
    let thisWeekEntries: Int
    let thisMonthEntries: Int
    let averageEntriesPerDay: Double
    let mostCommonCategory: DiaryCategory?
    let mostCommonMood: DiaryMood?
    let currentStreak: Int
    let longestStreak: Int
    
    init(entries: [DiaryEntry]) {
        self.totalEntries = entries.count
        
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        self.thisWeekEntries = entries.filter { 
            guard let date = $0.date else { return false }
            return date >= weekStart && date <= now 
        }.count
        
        self.thisMonthEntries = entries.filter { 
            guard let date = $0.date else { return false }
            return date >= monthStart && date <= now 
        }.count
        
        // 平均エントリー数
        if !entries.isEmpty {
            let firstEntry = entries.compactMap { $0.date }.min() ?? now
            let daysSinceFirst = calendar.dateComponents([.day], from: firstEntry, to: now).day ?? 1
            self.averageEntriesPerDay = Double(totalEntries) / Double(max(daysSinceFirst, 1))
        } else {
            self.averageEntriesPerDay = 0
        }
        
        // 最も多いカテゴリー
        let categoryCounts = Dictionary(grouping: entries, by: { $0.categoryEnum })
            .mapValues { $0.count }
        self.mostCommonCategory = categoryCounts.max(by: { $0.value < $1.value })?.key
        
        // 最も多い気分
        let moodCounts = Dictionary(grouping: entries, by: { $0.moodEnum })
            .mapValues { $0.count }
        self.mostCommonMood = moodCounts.max(by: { $0.value < $1.value })?.key
        
        // 連続記録日数の計算（簡易版）
        let sortedEntries = entries.compactMap { $0.date }.sorted(by: >)
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        
        var currentDate = calendar.startOfDay(for: now)
        
        for date in sortedEntries {
            let entryDate = calendar.startOfDay(for: date)
            
            if entryDate == currentDate {
                tempStreak += 1
            } else if entryDate == calendar.date(byAdding: .day, value: -1, to: currentDate) {
                currentDate = entryDate
                tempStreak += 1
            } else {
                longestStreak = max(longestStreak, tempStreak)
                tempStreak = 1
                currentDate = entryDate
            }
        }
        
        self.currentStreak = tempStreak
        self.longestStreak = max(longestStreak, tempStreak)
    }
}