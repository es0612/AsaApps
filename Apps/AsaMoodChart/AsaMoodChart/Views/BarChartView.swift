// AsaApps/Apps/AsaMoodChart/Views/BarChartView.swift
import SwiftUI
import Charts
import AsaUIKit

/// 気分分布を表示する棒グラフ
struct BarChartView: View {
    let moodEntries: [MoodEntry]
    @State private var selectedMood: String?
    @State private var chartType: BarChartType = .moodDistribution
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            headerView
            
            // チャートタイプ選択
            chartTypeSelector
            
            // 選択されたデータの詳細表示
            if let selectedMood = selectedMood {
                selectedMoodDetail(for: selectedMood)
            }
            
            // 棒グラフ
            Chart {
                switch chartType {
                case .moodDistribution:
                    moodDistributionChart()
                case .weeklyAverage:
                    weeklyAverageChart()
                }
            }
            .frame(height: 220)
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                        .foregroundStyle(AsaColors.mutedSage.opacity(0.2))
                    AxisTick()
                        .foregroundStyle(AsaColors.mutedSage)
                    AxisValueLabel {
                        if chartType == .moodDistribution,
                           let moodName = value.as(String.self) {
                            Text(emojiForMoodName(moodName))
                                .font(.title3)
                        } else if chartType == .weeklyAverage,
                                  let week = value.as(String.self) {
                            Text(week.replacingOccurrences(of: "年", with: "/").replacingOccurrences(of: "週", with: ""))
                                .font(.caption2)
                                .foregroundColor(AsaColors.darkSlate)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(AsaColors.softCream.opacity(0.8))
                    AxisTick()
                        .foregroundStyle(AsaColors.mutedSage)
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)")
                            .font(.caption)
                            .foregroundColor(AsaColors.darkSlate)
                    }
                }
            }
            .chartBackground { proxy in
                Rectangle()
                    .fill(AsaColors.softCream.opacity(0.1))
                    .cornerRadius(12)
            }
            .onTapGesture { location in
                selectedMood = findNearestMood(to: location)
            }
            .padding(.horizontal)
            
            // 統計情報
            statisticsView
        }
        .asaCardStyle()
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var headerView: some View {
        Text("気分の分析")
            .font(.headline)
            .foregroundColor(AsaColors.coffeeBrown)
            .padding(.horizontal)
    }
    
    @ViewBuilder
    private var chartTypeSelector: some View {
        Picker("チャートタイプ", selection: $chartType) {
            ForEach(BarChartType.allCases) { type in
                Text(type.title).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func selectedMoodDetail(for moodName: String) -> some View {
        HStack(spacing: 12) {
            Text(emojiForMoodName(moodName))
                .font(.title2)
                .scaleEffect(1.2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(moodName)
                    .font(.headline)
                    .foregroundColor(AsaColors.coffeeBrown)
                
                if chartType == .moodDistribution {
                    let count = moodCounts[moodName] ?? 0
                    let percentage = Double(count) / Double(moodEntries.count) * 100
                    Text("\(count)回 (\(String(format: "%.1f", percentage))%)")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(AsaColors.softCream.opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal)
        .transition(.scale.combined(with: .opacity))
    }
    
    @ViewBuilder
    private var statisticsView: some View {
        switch chartType {
        case .moodDistribution:
            moodDistributionStats
        case .weeklyAverage:
            weeklyAverageStats
        }
    }
    
    @ViewBuilder
    private var moodDistributionStats: some View {
        HStack(spacing: 20) {
            statisticsItem(
                title: "最多",
                value: mostFrequentMood,
                subtitle: moodCounts[mostFrequentMood].map { "\($0)回" } ?? "0回"
            )
            
            statisticsItem(
                title: "最少",
                value: leastFrequentMood,
                subtitle: moodCounts[leastFrequentMood].map { "\($0)回" } ?? "0回"
            )
            
            statisticsItem(
                title: "種類",
                value: "\(moodCounts.count)",
                subtitle: "気分タイプ"
            )
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var weeklyAverageStats: some View {
        HStack(spacing: 20) {
            let weeklyData = weeklyAverageMoods
            let maxWeek = weeklyData.max(by: { $0.value < $1.value })
            let minWeek = weeklyData.min(by: { $0.value < $1.value })
            
            statisticsItem(
                title: "最高週",
                value: String(format: "%.1f", maxWeek?.value ?? 0),
                subtitle: maxWeek?.week ?? "N/A"
            )
            
            statisticsItem(
                title: "最低週",
                value: String(format: "%.1f", minWeek?.value ?? 0),
                subtitle: minWeek?.week ?? "N/A"
            )
            
            statisticsItem(
                title: "週数",
                value: "\(weeklyData.count)",
                subtitle: "週間"
            )
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func statisticsItem(title: String, value: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)
            
            Text(value)
                .font(.headline.bold())
                .foregroundColor(AsaColors.coffeeBrown)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(AsaColors.darkSlate.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Chart Content
    
    @ChartContentBuilder
    private func moodDistributionChart() -> some ChartContent {
        ForEach(Array(moodCounts.keys.sorted()), id: \.self) { moodName in
            let count = moodCounts[moodName] ?? 0
            BarMark(
                x: .value("気分", moodName),
                y: .value("件数", count)
            )
            .foregroundStyle(
                selectedMood == moodName ? 
                AsaColors.coffeeBrown.gradient :
                colorForMood(moodName).gradient
            )
            .cornerRadius(8)
            .opacity(selectedMood == nil || selectedMood == moodName ? 1.0 : 0.6)
        }
    }
    
    @ChartContentBuilder
    private func weeklyAverageChart() -> some ChartContent {
        ForEach(weeklyAverageMoods, id: \.week) { weekData in
            BarMark(
                x: .value("週", weekData.week),
                y: .value("平均気分", weekData.value)
            )
            .foregroundStyle(AsaColors.mutedSage.gradient)
            .cornerRadius(6)
        }
    }
    
    // MARK: - Computed Properties
    
    private var moodCounts: [String: Int] {
        moodEntries.moodCounts
    }
    
    private var mostFrequentMood: String {
        moodCounts.max(by: { $0.value < $1.value })?.key ?? "😊"
    }
    
    private var leastFrequentMood: String {
        moodCounts.min(by: { $0.value < $1.value })?.key ?? "😊"
    }
    
    private var weeklyAverageMoods: [(week: String, value: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: moodEntries) { entry in
            let weekOfYear = calendar.component(.weekOfYear, from: entry.date)
            let year = calendar.component(.year, from: entry.date)
            return "\(year)年\(weekOfYear)週"
        }
        
        return grouped.map { (week: $0.key, value: $0.value.averageMoodValue) }
            .sorted { $0.week < $1.week }
    }
    
    // MARK: - Helper Methods
    
    private func emojiForMoodName(_ moodName: String) -> String {
        switch moodName {
        case "悲しい": return "😢"
        case "イライラ": return "😤"
        case "疲れ": return "😴"
        case "良い": return "😊"
        case "最高": return "😍"
        default: return "😊"
        }
    }
    
    private func colorForMood(_ moodName: String) -> Color {
        switch moodName {
        case "悲しい": return .blue
        case "イライラ": return .red
        case "疲れ": return AsaColors.mutedSage
        case "良い": return .green
        case "最高": return .purple
        default: return AsaColors.coffeeBrown
        }
    }
    
    private func findNearestMood(to location: CGPoint) -> String? {
        return moodCounts.keys.randomElement()
    }
}

// MARK: - BarChartType Enum

enum BarChartType: String, CaseIterable, Identifiable {
    case moodDistribution = "気分分布"
    case weeklyAverage = "週別平均"
    
    var id: String { rawValue }
    
    var title: String { rawValue }
}

// MARK: - Preview

#Preview {
    let sampleEntries = [
        MoodEntry(date: Date(), emoji: "😊"),
        MoodEntry(date: Date(), emoji: "😢"),
        MoodEntry(date: Date(), emoji: "😊"),
        MoodEntry(date: Date(), emoji: "😍"),
        MoodEntry(date: Date(), emoji: "😤"),
        MoodEntry(date: Date(), emoji: "😴"),
        MoodEntry(date: Date(), emoji: "😊")
    ]
    
    return BarChartView(moodEntries: sampleEntries)
        .padding()
        .background(AsaColors.softCream.opacity(0.1))
}