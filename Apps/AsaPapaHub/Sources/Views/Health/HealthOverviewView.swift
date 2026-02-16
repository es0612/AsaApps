import SwiftUI
import SwiftData
import Charts
import AsaPapaHubKit
import AsaUIKit

// MARK: - 健康オーバービュー

/// 健康ドメインの詳細ビュー
struct HealthOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dashboards: [HubDashboard] = []
    @State private var selectedPeriod: ChartPeriod = .week

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 期間セレクタ
                Picker("期間", selection: $selectedPeriod) {
                    ForEach(ChartPeriod.allCases, id: \.self) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(.segmented)

                // 歩数チャート
                StepsChartView(dashboards: dashboards)

                // 睡眠チャート
                SleepChartView(dashboards: dashboards)

                // アクティビティリング
                activityRingSection
            }
            .padding()
        }
        .navigationTitle("健康")
        .background(Color(.systemGroupedBackground))
        .task { await loadData() }
    }

    // MARK: - アクティビティリングセクション

    private var activityRingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日のアクティビティ")
                .font(.headline)

            HStack(spacing: 20) {
                ActivityRingView(
                    progress: stepsProgress,
                    color: .green,
                    label: "歩数",
                    value: "\(latestSteps)"
                )

                ActivityRingView(
                    progress: sleepProgress,
                    color: .blue,
                    label: "睡眠",
                    value: String(format: "%.1fh", latestSleep)
                )

                ActivityRingView(
                    progress: routineProgress,
                    color: .orange,
                    label: "朝活",
                    value: "\(latestScore)%"
                )
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
    }

    // MARK: - Private

    private func loadData() async {
        let calendar = Calendar.current
        let daysBack = selectedPeriod.dayCount
        let startDate = calendar.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<HubDashboard>(
            predicate: #Predicate { $0.date >= startDate },
            sortBy: [SortDescriptor(\.date)]
        )
        dashboards = (try? modelContext.fetch(descriptor)) ?? []
    }

    private var latestSteps: Int { dashboards.last?.stepsCount ?? 0 }
    private var latestSleep: Double { dashboards.last?.sleepHours ?? 0 }
    private var latestScore: Int { dashboards.last?.morningScore ?? 0 }
    private var stepsProgress: Double { Double(latestSteps) / 10000.0 }
    private var sleepProgress: Double { latestSleep / 8.0 }
    private var routineProgress: Double { Double(latestScore) / 100.0 }
}
