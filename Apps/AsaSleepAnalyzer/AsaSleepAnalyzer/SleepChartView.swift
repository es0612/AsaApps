//
//  SleepChartView.swift
//  AsaSleepAnalyzer
//
//  Created on 2025/08/05
//

import SwiftUI
import Charts

struct SleepChartView: View {
    let sleepData: [SleepData]
    let chartType: ChartType
    let timeRange: ChartTimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            chartHeader
            
            if sleepData.isEmpty {
                emptyStateView
            } else {
                chartContent
            }
        }
        .padding()
    }
    
    // MARK: - Chart Header
    
    private var chartHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chartType.title)
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Text(chartType.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            chartLegend
        }
    }
    
    // MARK: - Chart Legend
    
    private var chartLegend: some View {
        HStack(spacing: 16) {
            switch chartType {
            case .sleepDuration:
                LegendItem(color: Color("AsaCoffeeBrown"), label: "睡眠時間")
            case .sleepQuality:
                LegendItem(color: Color("AsaMocha"), label: "品質スコア")
            case .sleepEfficiency:
                LegendItem(color: Color("AsaMutedSage"), label: "睡眠効率")
            case .combined:
                VStack(alignment: .trailing, spacing: 2) {
                    LegendItem(color: Color("AsaCoffeeBrown"), label: "睡眠時間")
                    LegendItem(color: Color("AsaMocha"), label: "品質")
                }
            }
        }
        .font(.caption2)
    }
    
    // MARK: - Chart Content
    
    private var chartContent: some View {
        Group {
            switch chartType {
            case .sleepDuration:
                sleepDurationChart
            case .sleepQuality:
                sleepQualityChart
            case .sleepEfficiency:
                sleepEfficiencyChart
            case .combined:
                combinedChart
            }
        }
        .frame(height: chartHeight)
    }
    
    // MARK: - Sleep Duration Chart
    
    private var sleepDurationChart: some View {
        Chart(sleepData, id: \.date) { data in
            BarMark(
                x: .value("日付", data.date),
                y: .value("睡眠時間", data.totalSleepDuration / 3600)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color("AsaCoffeeBrown"),
                        Color("AsaCoffeeBrown").opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(4)
            
            // 目標ライン（8時間）
            RuleMark(y: .value("目標", 8.0))
                .foregroundStyle(Color("AsaMutedSage"))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
        }
        .chartYAxisLabel("時間")
        .chartXAxisLabel("日付")
        .chartYAxis {
            AxisMarks(values: .stride(by: 2)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let hours = value.as(Double.self) {
                        Text("\(Int(hours))h")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
    }
    
    // MARK: - Sleep Quality Chart
    
    private var sleepQualityChart: some View {
        Chart(sleepData, id: \.date) { data in
            LineMark(
                x: .value("日付", data.date),
                y: .value("品質スコア", data.qualityScore)
            )
            .foregroundStyle(Color("AsaMocha"))
            .lineStyle(StrokeStyle(lineWidth: 3))
            .symbol(Circle().strokeBorder(lineWidth: 2))
            .symbolSize(40)
            
            AreaMark(
                x: .value("日付", data.date),
                y: .value("品質スコア", data.qualityScore)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color("AsaMocha").opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartYScale(domain: 0...10)
        .chartYAxisLabel("品質スコア")
        .chartXAxisLabel("日付")
        .chartYAxis {
            AxisMarks(values: [0, 2.5, 5, 7.5, 10]) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let score = value.as(Double.self) {
                        Text("\(score, specifier: "%.1f")")
                            .font(.caption2)
                    }
                }
            }
        }
    }
    
    // MARK: - Sleep Efficiency Chart
    
    private var sleepEfficiencyChart: some View {
        Chart(sleepData, id: \.date) { data in
            LineMark(
                x: .value("日付", data.date),
                y: .value("効率", data.sleepEfficiency * 100)
            )
            .foregroundStyle(Color("AsaMutedSage"))
            .lineStyle(StrokeStyle(lineWidth: 3))
            .symbol(Circle().strokeBorder(lineWidth: 2))
            .symbolSize(40)
            
            // 理想効率ライン（85%）
            RuleMark(y: .value("理想", 85.0))
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [3]))
        }
        .chartYScale(domain: 0...100)
        .chartYAxisLabel("効率 (%)")
        .chartXAxisLabel("日付")
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let efficiency = value.as(Double.self) {
                        Text("\(Int(efficiency))%")
                            .font(.caption2)
                    }
                }
            }
        }
    }
    
    // MARK: - Combined Chart
    
    private var combinedChart: some View {
        Chart(sleepData, id: \.date) { data in
            // 睡眠時間（棒グラフ）
            BarMark(
                x: .value("日付", data.date),
                y: .value("睡眠時間", data.totalSleepDuration / 3600)
            )
            .foregroundStyle(Color("AsaCoffeeBrown").opacity(0.7))
            .cornerRadius(2)
            
            // 品質スコア（線グラフ）
            LineMark(
                x: .value("日付", data.date),
                y: .value("品質", data.qualityScore)
            )
            .foregroundStyle(Color("AsaMocha"))
            .lineStyle(StrokeStyle(lineWidth: 2))
            .symbol(Circle().strokeBorder(lineWidth: 1))
            .symbolSize(30)
        }
        .chartYAxisLabel("時間 / スコア")
        .chartXAxisLabel("日付")
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(Color("AsaMutedSage"))
            
            Text("データがありません")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Text("睡眠データが記録されるとグラフが表示されます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: chartHeight)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var chartHeight: CGFloat {
        switch chartType {
        case .sleepDuration, .sleepQuality, .sleepEfficiency:
            return 200
        case .combined:
            return 250
        }
    }
}

// MARK: - Supporting Views

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Enums

enum ChartType: String, CaseIterable {
    case sleepDuration = "睡眠時間"
    case sleepQuality = "睡眠品質"
    case sleepEfficiency = "睡眠効率"
    case combined = "総合"
    
    var title: String {
        switch self {
        case .sleepDuration:
            return "睡眠時間の推移"
        case .sleepQuality:
            return "睡眠品質の推移"
        case .sleepEfficiency:
            return "睡眠効率の推移"
        case .combined:
            return "総合睡眠データ"
        }
    }
    
    var subtitle: String {
        switch self {
        case .sleepDuration:
            return "日別の睡眠時間を表示"
        case .sleepQuality:
            return "睡眠品質スコアの変化"
        case .sleepEfficiency:
            return "実際の睡眠時間/ベッドにいた時間"
        case .combined:
            return "睡眠時間と品質の関係"
        }
    }
}

enum ChartTimeRange: String, CaseIterable {
    case week = "1週間"
    case month = "1ヶ月"
    case threeMonths = "3ヶ月"
    case sixMonths = "6ヶ月"
    
    var days: Int {
        switch self {
        case .week:
            return 7
        case .month:
            return 30
        case .threeMonths:
            return 90
        case .sixMonths:
            return 180
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            AsaCard {
                SleepChartView(
                    sleepData: SampleData.sleepData,
                    chartType: .sleepDuration,
                    timeRange: .week
                )
            }
            
            AsaCard {
                SleepChartView(
                    sleepData: SampleData.sleepData,
                    chartType: .sleepQuality,
                    timeRange: .week
                )
            }
            
            AsaCard {
                SleepChartView(
                    sleepData: SampleData.sleepData,
                    chartType: .combined,
                    timeRange: .week
                )
            }
        }
        .padding()
    }
    .background(Color("AsaSoftCream"))
}

// MARK: - Sample Data for Preview

struct SampleData {
    static let sleepData: [SleepData] = {
        let calendar = Calendar.current
        let today = Date()
        
        return (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return nil }
            
            return SleepData(
                date: date,
                totalSleepDuration: Double.random(in: 6.5...9.0) * 3600,
                sleepEfficiency: Double.random(in: 0.75...0.95),
                qualityScore: Double.random(in: 6.0...9.5)
            )
        }.reversed()
    }()
}