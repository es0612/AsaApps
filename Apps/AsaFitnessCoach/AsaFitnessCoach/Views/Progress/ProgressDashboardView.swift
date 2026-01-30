//
//  ProgressDashboardView.swift
//  AsaFitnessCoach
//
//  進捗ダッシュボード画面
//

import SwiftUI
import Charts

struct ProgressDashboardView: View {
    // MARK: - Properties

    @Bindable var viewModel: FitnessCoachViewModel
    @State private var progressVM = ProgressViewModel()
    @State private var selectedChart: ChartType = .duration
    @Environment(\.modelContext) private var modelContext

    enum ChartType: String, CaseIterable {
        case duration = "時間"
        case volume = "ボリューム"
        case frequency = "頻度"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 期間選択
                    timeRangePicker

                    // サマリーカード
                    summaryCards

                    // チャート
                    chartSection

                    // 週間カレンダー
                    weeklyCalendar

                    // プログレッシブオーバーロード提案
                    if !progressVM.overloadSuggestions.isEmpty {
                        overloadSection
                    }

                    // AI洞察
                    aiInsightsSection
                }
                .padding()
            }
            .navigationTitle("進捗")
            .refreshable {
                progressVM.refreshData()
            }
            .onAppear {
                progressVM.setModelContext(modelContext)
                progressVM.loadData()
            }
            .onChange(of: progressVM.selectedTimeRange) { _, _ in
                progressVM.loadData()
            }
        }
    }

    // MARK: - Sections

    private var timeRangePicker: some View {
        Picker("期間", selection: $progressVM.selectedTimeRange) {
            ForEach(ProgressViewModel.TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ProgressSummaryCard(
                title: "ワークアウト",
                value: "\(progressVM.totalWorkouts)",
                unit: "回",
                icon: "figure.run",
                color: .blue
            )

            ProgressSummaryCard(
                title: "合計時間",
                value: formatDuration(progressVM.totalDuration),
                unit: "",
                icon: "clock",
                color: .green
            )

            ProgressSummaryCard(
                title: "消費カロリー",
                value: "\(Int(progressVM.totalCalories))",
                unit: "kcal",
                icon: "flame.fill",
                color: .orange
            )

            ProgressSummaryCard(
                title: "総ボリューム",
                value: "\(Int(progressVM.totalVolume))",
                unit: "kg",
                icon: "scalemass",
                color: .purple
            )
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("トレンド")
                    .font(.headline)

                Spacer()

                Picker("チャート", selection: $selectedChart) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }

            Chart {
                ForEach(progressVM.dailyData) { day in
                    switch selectedChart {
                    case .duration:
                        BarMark(
                            x: .value("日付", day.date, unit: .day),
                            y: .value("時間", day.duration)
                        )
                        .foregroundStyle(Color.accentColor.gradient)

                    case .volume:
                        BarMark(
                            x: .value("日付", day.date, unit: .day),
                            y: .value("ボリューム", day.volume)
                        )
                        .foregroundStyle(Color.purple.gradient)

                    case .frequency:
                        BarMark(
                            x: .value("日付", day.date, unit: .day),
                            y: .value("回数", day.workoutCount)
                        )
                        .foregroundStyle(Color.green.gradient)
                    }
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: progressVM.selectedTimeRange == .week ? 1 : 7)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(formatAxisDate(date))
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var weeklyCalendar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今週の活動")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(progressVM.dailyData.suffix(7)) { day in
                    VStack(spacing: 8) {
                        Text(day.weekdayShort)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Circle()
                            .fill(day.hasWorkout ? Color.accentColor : Color(.systemGray5))
                            .frame(width: 36, height: 36)
                            .overlay {
                                if day.hasWorkout {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                }
                            }

                        Text(day.displayDate)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // ストリーク
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(progressVM.workoutStreak)日連続")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var overloadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(.green)
                Text("負荷増加の提案")
                    .font(.headline)
            }

            ForEach(progressVM.overloadSuggestions.prefix(5)) { suggestion in
                OverloadSuggestionCard(suggestion: suggestion)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("AI洞察")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 12) {
                InsightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "トレーニング頻度",
                    insight: generateFrequencyInsight()
                )

                InsightCard(
                    icon: "clock",
                    title: "平均セッション時間",
                    insight: generateDurationInsight()
                )

                InsightCard(
                    icon: "star.fill",
                    title: "モチベーション",
                    insight: generateMotivationInsight()
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Helper Methods

    private func formatDuration(_ minutes: TimeInterval) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hours > 0 {
            return "\(hours)h\(mins)m"
        }
        return "\(mins)分"
    }

    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = progressVM.selectedTimeRange == .week ? "E" : "M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    private func generateFrequencyInsight() -> String {
        let workoutsPerWeek = Double(progressVM.totalWorkouts) / Double(progressVM.selectedTimeRange.days) * 7
        if workoutsPerWeek >= 4 {
            return "素晴らしい！週\(Int(workoutsPerWeek))回のトレーニングを維持しています。"
        } else if workoutsPerWeek >= 2 {
            return "良いペースです。週\(Int(workoutsPerWeek))回のトレーニングを続けましょう。"
        } else {
            return "もう少し頻度を上げると効果が出やすくなります。"
        }
    }

    private func generateDurationInsight() -> String {
        let avgDuration = progressVM.averageSessionDuration
        if avgDuration >= 45 {
            return "1回あたり約\(Int(avgDuration))分の充実したセッションです。"
        } else if avgDuration >= 20 {
            return "平均\(Int(avgDuration))分のセッション。時間を有効活用しています。"
        } else {
            return "短いセッションでも継続が大切です。"
        }
    }

    private func generateMotivationInsight() -> String {
        let avgRating = progressVM.averageRating
        if avgRating >= 4 {
            return "高いモチベーションを維持できています！この調子で頑張りましょう。"
        } else if avgRating >= 3 {
            return "安定したモチベーションです。目標を見直すとさらに向上するかもしれません。"
        } else {
            return "新しい目標やルーティンを試してみましょう。"
        }
    }
}

// MARK: - Supporting Views

struct ProgressSummaryCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct OverloadSuggestionCard: View {
    let suggestion: ProgressiveOverloadSuggestion

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.exerciseName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(suggestion.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(suggestion.displayIncrease)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)

                Text(suggestion.displayWeightChange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let insight: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(insight)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Preview

#Preview {
    ProgressDashboardView(viewModel: FitnessCoachViewModel())
}
