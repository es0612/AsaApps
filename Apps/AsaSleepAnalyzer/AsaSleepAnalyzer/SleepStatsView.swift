//
//  SleepStatsView.swift
//  AsaSleepAnalyzer
//
//  Created on 2025/08/05
//

import SwiftUI
import Charts

struct SleepStatsView: View {
    @ObservedObject var viewModel: SleepAnalyzerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeRange: TimeRange = .week
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 時間範囲選択
                    timeRangeSelector
                    
                    // 総合統計
                    overallStatsCard
                    
                    // 睡眠時間チャート
                    sleepDurationChart
                    
                    // 睡眠品質分析
                    sleepQualityAnalysis
                    
                    // 週間パターン分析
                    weeklyPatternAnalysis
                    
                    // 睡眠効率統計
                    sleepEfficiencyStats
                    
                }
                .padding()
            }
            .navigationTitle("睡眠統計")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
        }
        .accentColor(Color("AsaCoffeeBrown"))
    }
    
    // MARK: - 時間範囲選択
    
    private var timeRangeSelector: some View {
        AsaCard {
            HStack {
                Text("表示期間")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Spacer()
                
                Picker("時間範囲", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: 200)
            }
            .padding()
        }
    }
    
    // MARK: - 総合統計
    
    private var overallStatsCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("総合統計")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    StatCard(
                        title: "平均睡眠時間",
                        value: viewModel.formatDuration(viewModel.averageSleepDuration),
                        icon: "moon.fill",
                        color: Color("AsaCoffeeBrown")
                    )
                    
                    StatCard(
                        title: "平均睡眠効率",
                        value: viewModel.formatEfficiency(viewModel.averageSleepEfficiency),
                        icon: "gauge.medium",
                        color: Color("AsaMutedSage")
                    )
                    
                    StatCard(
                        title: "平均品質スコア",
                        value: viewModel.formatScore(viewModel.averageQualityScore),
                        icon: "star.fill",
                        color: Color("AsaMocha")
                    )
                    
                    StatCard(
                        title: "総睡眠時間",
                        value: viewModel.formatDuration(viewModel.totalSleepHours),
                        icon: "clock.fill",
                        color: Color("AsaDarkSlate")
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - 睡眠時間チャート
    
    private var sleepDurationChart: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("睡眠時間の推移")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Spacer()
                    
                    Text("目標: \(viewModel.formatDuration(viewModel.dailySleepGoal))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !viewModel.weeklySleepData.isEmpty {
                    Chart(viewModel.weeklySleepData, id: \.date) { sleepData in
                        LineMark(
                            x: .value("日付", sleepData.date),
                            y: .value("睡眠時間", sleepData.totalSleepDuration / 3600)
                        )
                        .foregroundStyle(Color("AsaCoffeeBrown"))
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        AreaMark(
                            x: .value("日付", sleepData.date),
                            y: .value("睡眠時間", sleepData.totalSleepDuration / 3600)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("AsaCoffeeBrown").opacity(0.3), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        // 目標ライン
                        RuleMark(y: .value("目標", viewModel.dailySleepGoal / 3600))
                            .foregroundStyle(Color("AsaMutedSage"))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    }
                    .frame(height: 200)
                    .chartYAxisLabel("時間")
                    .chartXAxisLabel("日付")
                } else {
                    Text("データがありません")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding()
        }
    }
    
    // MARK: - 睡眠品質分析
    
    private var sleepQualityAnalysis: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("睡眠品質分析")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                let qualityDistribution = getQualityDistribution()
                
                if !qualityDistribution.isEmpty {
                    ForEach(qualityDistribution, id: \.level) { item in
                        QualityDistributionRow(
                            level: item.level,
                            count: item.count,
                            percentage: item.percentage
                        )
                    }
                } else {
                    Text("品質データがありません")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding()
        }
    }
    
    // MARK: - 週間パターン分析
    
    private var weeklyPatternAnalysis: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("曜日別睡眠パターン")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                let weekdayData = getWeekdayAverages()
                
                if !weekdayData.isEmpty {
                    Chart(weekdayData, id: \.weekday) { data in
                        BarMark(
                            x: .value("曜日", data.weekday),
                            y: .value("平均睡眠時間", data.averageDuration / 3600)
                        )
                        .foregroundStyle(Color("AsaCoffeeBrown"))
                        .cornerRadius(4)
                    }
                    .frame(height: 150)
                    .chartYAxisLabel("時間")
                } else {
                    Text("週間データがありません")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding()
        }
    }
    
    // MARK: - 睡眠効率統計
    
    private var sleepEfficiencyStats: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("睡眠効率分析")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                let efficiencyData = viewModel.weeklySleepData.filter { $0.sleepEfficiency > 0 }
                
                if !efficiencyData.isEmpty {
                    let bestEfficiency = efficiencyData.max(by: { $0.sleepEfficiency < $1.sleepEfficiency })
                    let worstEfficiency = efficiencyData.min(by: { $0.sleepEfficiency < $1.sleepEfficiency })
                    
                    VStack(spacing: 12) {
                        if let best = bestEfficiency {
                            EfficiencyRow(
                                title: "最高効率",
                                date: best.date,
                                efficiency: best.sleepEfficiency,
                                color: .green
                            )
                        }
                        
                        if let worst = worstEfficiency {
                            EfficiencyRow(
                                title: "最低効率",
                                date: worst.date,
                                efficiency: worst.sleepEfficiency,
                                color: .red
                            )
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("改善のヒント")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            Spacer()
                        }
                        
                        if viewModel.averageSleepEfficiency < 0.85 {
                            SleepTip(text: "就寝前のスクリーン時間を減らしましょう")
                            SleepTip(text: "規則正しい就寝時間を心がけましょう")
                            SleepTip(text: "寝室の温度を涼しく保ちましょう")
                        } else {
                            SleepTip(text: "素晴らしい睡眠効率です！現在の習慣を続けましょう")
                        }
                    }
                } else {
                    Text("効率データがありません")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private func getQualityDistribution() -> [QualityDistributionItem] {
        let validData = viewModel.weeklySleepData.filter { $0.qualityScore > 0 }
        guard !validData.isEmpty else { return [] }
        
        var distribution: [SleepQualityLevel: Int] = [:]
        
        for sleepData in validData {
            let level = sleepData.qualityLevel
            distribution[level, default: 0] += 1
        }
        
        return distribution.map { level, count in
            QualityDistributionItem(
                level: level,
                count: count,
                percentage: Double(count) / Double(validData.count)
            )
        }.sorted { $0.level.rawValue < $1.level.rawValue }
    }
    
    private func getWeekdayAverages() -> [WeekdayData] {
        let calendar = Calendar.current
        var weekdayData: [Int: [TimeInterval]] = [:]
        
        for sleepData in viewModel.weeklySleepData {
            let weekday = calendar.component(.weekday, from: sleepData.date)
            weekdayData[weekday, default: []].append(sleepData.totalSleepDuration)
        }
        
        return weekdayData.compactMap { weekday, durations in
            guard !durations.isEmpty else { return nil }
            let averageDuration = durations.reduce(0, +) / Double(durations.count)
            return WeekdayData(
                weekday: weekdayName(from: weekday),
                averageDuration: averageDuration
            )
        }.sorted { $0.weekday < $1.weekday }
    }
    
    private func weekdayName(from weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.shortWeekdaySymbols[weekday - 1]
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color("AsaDarkSlate"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct QualityDistributionRow: View {
    let level: SleepQualityLevel
    let count: Int
    let percentage: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: level.systemImageName)
                    .foregroundColor(Color(level.color))
                    .frame(width: 20)
                
                Text(level.rawValue)
                    .font(.body)
                    .fontWeight(.medium)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(count)日")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Text(String(format: "%.1f%%", percentage * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: percentage)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                .tint(Color(level.color))
        }
        .padding(.vertical, 4)
    }
}

struct EfficiencyRow: View {
    let title: String
    let date: Date
    let efficiency: Double
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatDate(date))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaDarkSlate"))
            }
            
            Spacer()
            
            Text(String(format: "%.1f%%", efficiency * 100))
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d (E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct SleepTip: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(Color("AsaMocha"))
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Data Models

enum TimeRange: String, CaseIterable {
    case week = "週"
    case month = "月"
    case threeMonths = "3ヶ月"
    
    var displayName: String {
        return self.rawValue
    }
}

struct QualityDistributionItem {
    let level: SleepQualityLevel
    let count: Int
    let percentage: Double
}

struct WeekdayData {
    let weekday: String
    let averageDuration: TimeInterval
}

#Preview {
    SleepStatsView(viewModel: SleepAnalyzerViewModel())
}