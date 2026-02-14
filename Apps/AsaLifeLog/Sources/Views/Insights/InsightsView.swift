import SwiftUI
import AsaLifeLogKit

// MARK: - InsightsView

/// インサイト表示ビュー
struct InsightsView: View {
    @Bindable var viewModel: InsightsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        // 日次サマリー
                        DailySummaryCard(
                            insight: viewModel.dailyInsight,
                            morningScore: viewModel.morningScore
                        )

                        // 週次サマリー
                        WeeklySummaryCard(insight: viewModel.weeklyInsight)

                        // パターン検出
                        if !viewModel.patterns.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("検出されたパターン")
                                    .font(.headline)
                                    .padding(.horizontal)

                                ForEach(viewModel.patterns) { pattern in
                                    PatternCard(pattern: pattern)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("インサイト")
            .task {
                await viewModel.generateTodayInsights()
                await viewModel.generateWeeklyInsights()
                await viewModel.detectPatterns()
            }
            .refreshable {
                await viewModel.generateTodayInsights()
                await viewModel.generateWeeklyInsights()
                await viewModel.detectPatterns()
            }
        }
    }
}
