import SwiftUI
import AsaLifeLogKit

// MARK: - DailyStatsCard

/// 日次統計カード
struct DailyStatsCard: View {
    let summary: DailySummary?
    let morningScore: Int

    var body: some View {
        AsaLifeLogCard {
            VStack(spacing: 12) {
                HStack {
                    Text("今日のサマリー")
                        .font(.headline)
                    Spacer()
                }

                HStack(spacing: 16) {
                    StatRing(
                        value: Double(morningScore),
                        maxValue: 100,
                        label: "朝活",
                        valueText: "\(morningScore)",
                        ringColor: .orange
                    )

                    StatRing(
                        value: Double(summary?.totalSteps ?? 0),
                        maxValue: 10000,
                        label: "歩数",
                        valueText: "\(summary?.totalSteps ?? 0)",
                        ringColor: .blue
                    )

                    StatRing(
                        value: summary?.sleepHours ?? 0,
                        maxValue: 8,
                        label: "睡眠",
                        valueText: String(format: "%.1fh", summary?.sleepHours ?? 0),
                        ringColor: .purple
                    )

                    StatRing(
                        value: Double(summary?.entryCount ?? 0),
                        maxValue: 20,
                        label: "記録",
                        valueText: "\(summary?.entryCount ?? 0)",
                        ringColor: .green
                    )
                }
            }
        }
    }
}
