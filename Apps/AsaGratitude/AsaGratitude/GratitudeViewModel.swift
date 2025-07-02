//
//  GratitudeViewModel.swift
//  AsaGratitude
//  
//  Created on 2025/07/02
//

import Foundation
import SwiftUI

class GratitudeViewModel: ObservableObject {
    @Published var gratitudeEntries: [GratitudeEntry] = []
    @Published var isShowingAddEntry = false
    @Published var selectedEntry: GratitudeEntry?
    @Published var currentQuote: GratitudeQuote = GratitudeQuote.randomQuote()
    @Published var selectedDate = Date()
    
    private let userDefaults = UserDefaults.standard
    private let entriesKey = "GratitudeEntries"
    
    init() {
        loadData()
        refreshQuote()
    }
    
    // MARK: - Data Management
    func loadData() {
        if let entryData = userDefaults.data(forKey: entriesKey),
           let entries = try? JSONDecoder().decode([GratitudeEntry].self, from: entryData) {
            self.gratitudeEntries = entries.sorted { $0.date > $1.date }
        }
    }
    
    func saveData() {
        if let entryData = try? JSONEncoder().encode(gratitudeEntries) {
            userDefaults.set(entryData, forKey: entriesKey)
        }
    }
    
    // MARK: - Entry Management
    func addGratitudeEntry(_ entry: GratitudeEntry) {
        gratitudeEntries.append(entry)
        gratitudeEntries.sort { $0.date > $1.date }
        saveData()
    }
    
    func updateGratitudeEntry(_ entry: GratitudeEntry) {
        if let index = gratitudeEntries.firstIndex(where: { $0.id == entry.id }) {
            gratitudeEntries[index] = entry
            gratitudeEntries.sort { $0.date > $1.date }
            saveData()
        }
    }
    
    func deleteGratitudeEntry(_ entry: GratitudeEntry) {
        gratitudeEntries.removeAll { $0.id == entry.id }
        saveData()
    }
    
    func deleteGratitudeEntries(at offsets: IndexSet) {
        gratitudeEntries.remove(atOffsets: offsets)
        saveData()
    }
    
    // MARK: - UI Helpers
    func showAddEntry() {
        isShowingAddEntry = true
    }
    
    func selectEntry(_ entry: GratitudeEntry) {
        selectedEntry = entry
    }
    
    func clearSelection() {
        selectedEntry = nil
    }
    
    func refreshQuote() {
        currentQuote = GratitudeQuote.randomQuote()
    }
    
    // MARK: - Data Filtering
    var todayEntries: [GratitudeEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return gratitudeEntries.filter { entry in
            entry.date >= today && entry.date < tomorrow
        }
    }
    
    var thisWeekEntries: [GratitudeEntry] {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        return gratitudeEntries.filter { entry in
            entry.date >= weekStart && entry.date <= now
        }
    }
    
    var thisMonthEntries: [GratitudeEntry] {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return gratitudeEntries.filter { entry in
            entry.date >= monthStart && entry.date <= now
        }
    }
    
    func entriesForDate(_ date: Date) -> [GratitudeEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return gratitudeEntries.filter { entry in
            entry.date >= startOfDay && entry.date < endOfDay
        }
    }
    
    func entriesForCategory(_ category: GratitudeCategory) -> [GratitudeEntry] {
        return gratitudeEntries.filter { $0.category == category }
    }
    
    // MARK: - Statistics
    var stats: GratitudeStats {
        return GratitudeStats(entries: gratitudeEntries)
    }
    
    var recentEntries: [GratitudeEntry] {
        return Array(gratitudeEntries.prefix(5))
    }
    
    var randomEntry: GratitudeEntry? {
        return gratitudeEntries.randomElement()
    }
    
    // MARK: - Weekly View Data
    var weeklyData: [(Date, [GratitudeEntry])] {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        var weeklyData: [(Date, [GratitudeEntry])] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: weekStart)!
            let entries = entriesForDate(date)
            weeklyData.append((date, entries))
        }
        
        return weeklyData
    }
    
    // MARK: - Category Statistics
    var categoryStats: [(GratitudeCategory, Int)] {
        let categoryCounts = Dictionary(grouping: gratitudeEntries, by: { $0.category })
            .mapValues { $0.count }
        
        return GratitudeCategory.allCases.compactMap { category in
            if let count = categoryCounts[category], count > 0 {
                return (category, count)
            }
            return nil
        }.sorted { $0.1 > $1.1 }
    }
    
    // MARK: - Mood Statistics
    var moodStats: [(GratitudeMood, Int)] {
        let moodCounts = Dictionary(grouping: gratitudeEntries, by: { $0.moodLevel })
            .mapValues { $0.count }
        
        return GratitudeMood.allCases.compactMap { mood in
            if let count = moodCounts[mood], count > 0 {
                return (mood, count)
            }
            return nil
        }.sorted { $0.0.rawValue > $1.0.rawValue }
    }
    
    // MARK: - Search
    func searchEntries(query: String) -> [GratitudeEntry] {
        if query.isEmpty {
            return gratitudeEntries
        }
        
        return gratitudeEntries.filter { entry in
            entry.content.localizedCaseInsensitiveContains(query) ||
            entry.category.displayName.localizedCaseInsensitiveContains(query)
        }
    }
}