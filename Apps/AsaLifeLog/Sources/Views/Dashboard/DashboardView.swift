import SwiftUI
import Charts
import AsaLifeLogKit

// MARK: - DashboardView

/// ダッシュボード表示ビュー
struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 期間セレクタ
                    Picker("期間", selection: $viewModel.selectedPeriod) {
                        ForEach(ChartPeriod.allCases, id: \.self) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: viewModel.selectedPeriod) {
                        Task { await viewModel.changePeriod(viewModel.selectedPeriod) }
                    }

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        // 日次統計カード
                        DailyStatsCard(
                            summary: viewModel.dailySummary,
                            morningScore: viewModel.morningScore
                        )
                        .padding(.horizontal)

                        // チャートグリッド
                        LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                            MoodDistributionChart(distribution: viewModel.moodDistribution)
                            StepsLineChart(data: viewModel.stepsData)
                            SleepBarChart(data: viewModel.sleepData)
                            ActivityBreakdownChart(breakdown: viewModel.activityBreakdown)
                            WeeklyTrendChart(stepsData: viewModel.stepsData, sleepData: viewModel.sleepData)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("ダッシュボード")
            .task {
                await viewModel.loadDashboardData()
            }
            .refreshable {
                await viewModel.loadDashboardData()
            }
        }
    }
}
