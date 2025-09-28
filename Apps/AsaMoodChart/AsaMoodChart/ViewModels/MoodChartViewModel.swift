// AsaApps/Apps/AsaMoodChart/ViewModels/MoodChartViewModel.swift
import Foundation
import Observation

/// 気分チャート画面のViewModel（@Observableパターン）
@Observable
final class MoodChartViewModel {
    
    // MARK: - Properties
    
    /// 全気分データ
    var allMoodEntries: [MoodEntry] = []
    
    /// 現在選択されている期間フィルター
    var selectedPeriod: TimePeriod = .oneMonth
    
    /// ロード中フラグ
    var isLoading = false
    
    /// エラーメッセージ
    var errorMessage: String?
    
    // MARK: - Computed Properties
    
    /// フィルタリングされた気分データ
    var filteredMoodEntries: [MoodEntry] {
        switch selectedPeriod {
        case .oneWeek:
            return allMoodEntries.entriesInLast(days: 7)
        case .oneMonth:
            return allMoodEntries.entriesInLast(days: 30)
        case .threeMonths:
            return allMoodEntries.entriesInLast(days: 90)
        case .all:
            return allMoodEntries
        }
    }
    
    /// ソート済み気分データ（時系列順）
    var sortedMoodEntries: [MoodEntry] {
        filteredMoodEntries.sortedByDate
    }
    
    /// 平均気分値
    var averageMoodValue: Double {
        filteredMoodEntries.averageMoodValue
    }
    
    /// 最頻気分
    var mostFrequentMood: String {
        filteredMoodEntries.mostFrequentMood
    }
    
    /// 記録日数
    var totalRecordDays: Int {
        filteredMoodEntries.count
    }
    
    /// 気分別件数
    var moodCounts: [String: Int] {
        filteredMoodEntries.moodCounts
    }
    
    /// 日別平均気分値（線グラフ用）
    var dailyAverageMoods: [(date: String, value: Double)] {
        let grouped = filteredMoodEntries.groupedByDay
        return grouped.map { (date: $0.key, value: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    /// 気分分布データ（円グラフ用）
    var moodDistribution: [(mood: String, count: Int, percentage: Double)] {
        let counts = moodCounts
        let total = Double(filteredMoodEntries.count)
        
        return counts.map { (mood: $0.key, count: $0.value, percentage: Double($0.value) / total * 100) }
            .sorted { $0.count > $1.count }
    }
    
    /// 週別平均気分（棒グラフ用）
    var weeklyAverageMoods: [(week: String, value: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredMoodEntries) { entry in
            let weekOfYear = calendar.component(.weekOfYear, from: entry.date)
            let year = calendar.component(.year, from: entry.date)
            return "\(year)年\(weekOfYear)週"
        }
        
        return grouped.map { (week: $0.key, value: $0.value.averageMoodValue) }
            .sorted { $0.week < $1.week }
    }
    
    // MARK: - Initialization
    
    init() {
        loadMoodEntries()
    }
    
    // MARK: - Methods
    
    /// AsaMoodTrackerからデータを読み込み（UserDefaults互換）
    func loadMoodEntries() {
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            if let data = UserDefaults.standard.data(forKey: "moodEntries") {
                do {
                    let savedEntries = try JSONDecoder().decode([MoodEntry].self, from: data)
                    allMoodEntries = savedEntries
                } catch {
                    errorMessage = "データの読み込みに失敗しました: \(error.localizedDescription)"
                    // エラー時はデモデータを使用
                    allMoodEntries = generateDemoData()
                }
            } else {
                // デモデータを生成（テスト用）
                allMoodEntries = generateDemoData()
            }
            isLoading = false
        }
    }
    
    /// 期間フィルターを変更
    func changePeriod(to period: TimePeriod) {
        selectedPeriod = period
    }
    
    /// データを手動で更新
    func refreshData() {
        loadMoodEntries()
    }
    
    // MARK: - Private Methods
    
    /// デモデータを生成（開発・テスト用）
    private func generateDemoData() -> [MoodEntry] {
        let calendar = Calendar.current
        let emojis = ["😊", "😢", "😤", "😍", "😴"]
        var demoEntries: [MoodEntry] = []
        
        // 過去30日間のランダムデータを生成
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let randomEmoji = emojis.randomElement() ?? "😊"
                let entry = MoodEntry(date: date, emoji: randomEmoji)
                demoEntries.append(entry)
            }
        }
        
        return demoEntries.sortedByDate
    }
}

// MARK: - TimePeriod Enum

/// 期間フィルター
enum TimePeriod: String, CaseIterable, Identifiable {
    case oneWeek = "1週間"
    case oneMonth = "1ヶ月"
    case threeMonths = "3ヶ月"
    case all = "すべて"
    
    var id: String { rawValue }
    
    /// 期間の説明
    var description: String {
        switch self {
        case .oneWeek:
            return "過去1週間の気分データ"
        case .oneMonth:
            return "過去1ヶ月の気分データ"
        case .threeMonths:
            return "過去3ヶ月の気分データ"
        case .all:
            return "すべての気分データ"
        }
    }
}