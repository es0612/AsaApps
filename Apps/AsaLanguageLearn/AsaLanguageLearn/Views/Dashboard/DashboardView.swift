//
//  DashboardView.swift
//  AsaLanguageLearn
//
//  ダッシュボード（統計）画面
//

import Charts
import SwiftData
import SwiftUI

struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 概要カード
                summaryCards

                // 週間チャート
                WeeklyChartView(data: viewModel.weeklyData)

                // 習熟レベル分布
                masteryDistribution

                // 詳細統計
                detailedStats
            }
            .padding()
        }
        .navigationTitle("統計")
        .navigationBarTitleDisplayMode(.large)
        .background(Color("AsaSoftCream").opacity(0.3))
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 16) {
            SummaryCard(
                title: "学習時間",
                value: viewModel.totalStudyTimeText,
                icon: "clock.fill",
                color: Color("AsaCoffeeBrown")
            )

            SummaryCard(
                title: "連続日数",
                value: "\(viewModel.currentStreak)日",
                icon: "flame.fill",
                color: .orange
            )

            SummaryCard(
                title: "正解率",
                value: viewModel.accuracyText,
                icon: "target",
                color: .green
            )

            SummaryCard(
                title: "習得済み",
                value: "\(viewModel.masteredItemsCount)",
                icon: "checkmark.seal.fill",
                color: .blue
            )
        }
    }

    // MARK: - Mastery Distribution

    private var masteryDistribution: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("習熟レベル分布")
                .font(.headline)

            HStack(spacing: 0) {
                ForEach(MasteryLevel.allCases, id: \.rawValue) { level in
                    let count = viewModel.masteryLevelCounts[level] ?? 0
                    let total = viewModel.masteryLevelCounts.values.reduce(0, +)
                    let percentage = total > 0 ? Double(count) / Double(total) : 0

                    if percentage > 0 {
                        Rectangle()
                            .fill(level.color)
                            .frame(width: max(CGFloat(percentage) * 300, 20))
                            .overlay(
                                Text("\(count)")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            .frame(height: 30)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // 凡例
            HStack(spacing: 16) {
                ForEach(MasteryLevel.allCases, id: \.rawValue) { level in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(level.color)
                            .frame(width: 10, height: 10)

                        Text(level.displayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    // MARK: - Detailed Stats

    private var detailedStats: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("詳細統計")
                .font(.headline)

            VStack(spacing: 12) {
                StatRow(
                    label: "完了レッスン",
                    value: "\(viewModel.completedLessonsCount)",
                    icon: "book.fill"
                )

                Divider()

                StatRow(
                    label: "復習待ち",
                    value: "\(viewModel.dueItemsCount)",
                    icon: "arrow.clockwise"
                )

                Divider()

                StatRow(
                    label: "最高連続日数",
                    value: "\(viewModel.bestStreak)日",
                    icon: "crown.fill"
                )
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(.title2.bold())
                .foregroundColor(Color("AsaDarkSlate"))

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color("AsaCoffeeBrown"))
                .frame(width: 24)

            Text(label)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserProfile.self, StudySession.self, LearningItem.self, configurations: config)

    NavigationStack {
        DashboardView(viewModel: DashboardViewModel(modelContext: container.mainContext))
    }
}
