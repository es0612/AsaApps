//
//  WorkoutProgressView.swift
//  AsaWorkoutPlanner
//
//  進捗トラッキング画面
//

import SwiftUI
import Charts
import AsaUIKit

struct WorkoutProgressView: View {
    // MARK: - Properties
    
    @Bindable var viewModel: WorkoutPlannerViewModel
    @State private var selectedTimeRange = TimeRange.week
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 統計サマリー
                    statisticsSummary
                    
                    // 時間範囲選択
                    Picker("期間", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // ワークアウト頻度チャート
                    workoutFrequencyChart
                    
                    // ストリークカード
                    streakCard
                    
                    // 最近のパフォーマンス
                    recentPerformance
                }
                .padding(.vertical)
            }
            .navigationTitle("進捗")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.updateStatistics()
            }
        }
    }
    
    // MARK: - Components
    
    private var statisticsSummary: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ProgressStatCard(
                    title: "総ワークアウト",
                    value: "\(viewModel.totalWorkouts)",
                    icon: "figure.run",
                    color: AsaColors.coffeeBrown
                )
                
                ProgressStatCard(
                    title: "合計時間",
                    value: formatHours(viewModel.totalDuration),
                    icon: "clock.fill",
                    color: AsaColors.mocha
                )
            }
            
            HStack(spacing: 16) {
                ProgressStatCard(
                    title: "消費カロリー",
                    value: "\(Int(viewModel.totalCaloriesBurned))",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: AsaColors.softCream
                )
                
                ProgressStatCard(
                    title: "週間目標",
                    value: "\(viewModel.weeklyProgress)/\(viewModel.weeklyGoal)",
                    icon: "target",
                    color: AsaColors.mutedSage
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var workoutFrequencyChart: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("ワークアウト頻度")
                    .font(.headline)
                
                Chart {
                    ForEach(workoutChartData(), id: \.date) { data in
                        BarMark(
                            x: .value("日付", data.date, unit: selectedTimeRange == .week ? .day : (selectedTimeRange == .month ? .weekOfMonth : .month)),
                            y: .value("回数", data.count)
                        )
                        .foregroundStyle(Color(AsaColors.coffeeBrown))
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    switch selectedTimeRange {
                    case .week:
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                        }
                    case .month:
                        AxisMarks(values: .stride(by: .weekOfMonth)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(weekLabel(for: date))
                                }
                            }
                        }
                    case .year:
                        AxisMarks(values: .stride(by: .month)) { _ in
                            AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
    
    private var streakCard: some View {
        AsaCard {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("連続記録")
                        .font(.headline)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(viewModel.currentStreak)")
                            .font(.system(size: 48, weight: .bold))
                        Text("日")
                            .font(.title3)
                            .foregroundColor(Color(AsaColors.mutedSage))
                    }
                    
                    Text(streakMessage)
                        .font(.caption)
                        .foregroundColor(Color(AsaColors.mutedSage))
                }
                
                Spacer()
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 60))
                    .foregroundColor(streakColor)
            }
            .padding()
        }
        .padding(.horizontal)
    }
    
    private var recentPerformance: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近のパフォーマンス")
                .font(.headline)
                .padding(.horizontal)
            
            if viewModel.recentSessions.isEmpty {
                Text("まだセッションがありません")
                    .font(.subheadline)
                    .foregroundColor(Color(AsaColors.mutedSage))
                    .padding()
            } else {
                ForEach(viewModel.recentSessions.prefix(5)) { session in
                    PerformanceRow(session: session)
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var streakMessage: String {
        switch viewModel.currentStreak {
        case 0:
            return "今日から始めましょう！"
        case 1...3:
            return "良いスタートです！"
        case 4...7:
            return "1週間達成まであと少し！"
        case 8...14:
            return "素晴らしい継続力！"
        case 15...30:
            return "習慣化されています！"
        default:
            return "驚異的な継続力！"
        }
    }
    
    private var streakColor: Color {
        switch viewModel.currentStreak {
        case 0...3:
            return Color(AsaColors.mutedSage)
        case 4...7:
            return Color(AsaColors.softCream)
        case 8...14:
            return Color(AsaColors.mocha)
        default:
            return Color(AsaColors.coffeeBrown)
        }
    }
    
    private func formatHours(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }

    private func weekLabel(for date: Date) -> String {
        let calendar = Calendar.current
        let weekOfMonth = calendar.component(.weekOfMonth, from: date)
        return "第\(weekOfMonth)週"
    }

    private func workoutChartData() -> [ChartData] {
        let calendar = Calendar.current
        var data: [ChartData] = []

        // 期間に応じてデータを集計
        switch selectedTimeRange {
        case .week:
            // 週間データ（過去7日）
            for i in 0..<7 {
                let date = calendar.date(byAdding: .day, value: -i, to: Date())!
                let dayStart = calendar.startOfDay(for: date)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

                let count = viewModel.recentSessions.filter { session in
                    session.isCompleted &&
                    session.startTime >= dayStart &&
                    session.startTime < dayEnd
                }.count

                data.append(ChartData(date: dayStart, count: count))
            }
            return data.reversed()

        case .month:
            // 月間データ（過去4週）
            for i in 0..<4 {
                let date = calendar.date(byAdding: .weekOfYear, value: -i, to: Date())!
                let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
                let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!

                let count = viewModel.recentSessions.filter { session in
                    session.isCompleted &&
                    session.startTime >= weekStart &&
                    session.startTime < weekEnd
                }.count

                data.append(ChartData(date: weekStart, count: count))
            }
            return data.reversed()

        case .year:
            // 年間データ（過去12ヶ月）
            for i in 0..<12 {
                let date = calendar.date(byAdding: .month, value: -i, to: Date())!
                let monthStart = calendar.dateInterval(of: .month, for: date)?.start ?? date
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!

                let count = viewModel.recentSessions.filter { session in
                    session.isCompleted &&
                    session.startTime >= monthStart &&
                    session.startTime < monthEnd
                }.count

                data.append(ChartData(date: monthStart, count: count))
            }
            return data.reversed()
        }
    }
}

// MARK: - Supporting Types

enum TimeRange: String, CaseIterable {
    case week = "週"
    case month = "月"
    case year = "年"
}

struct ChartData {
    let date: Date
    let count: Int
}

struct ProgressStatCard: View {
    let title: String
    let value: String
    var unit: String = ""
    let icon: String
    let color: Color
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Spacer()
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color(AsaColors.mutedSage))
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(Color(AsaColors.mutedSage))
                    }
                }
            }
            .padding()
        }
    }
}

struct PerformanceRow: View {
    let session: WorkoutSession
    
    var body: some View {
        AsaCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.workoutPlan?.name ?? "ワークアウト")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(session.sessionDate)
                        .font(.caption)
                        .foregroundColor(Color(AsaColors.mutedSage))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        if let rating = session.rating {
                            Text(rating.emoji)
                                .font(.title3)
                        }
                        
                        Text("\(session.completionPercentage)%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(completionColor(for: session.completionPercentage))
                    }
                    
                    Text("\(Int(session.totalCaloriesBurned)) kcal")
                        .font(.caption)
                        .foregroundColor(Color(AsaColors.mutedSage))
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
    
    private func completionColor(for percentage: Int) -> Color {
        if percentage >= 100 {
            return .green
        } else if percentage >= 70 {
            return .orange
        } else {
            return .red
        }
    }
}