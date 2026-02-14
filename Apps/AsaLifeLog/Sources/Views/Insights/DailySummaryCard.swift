import SwiftUI
import AsaLifeLogKit

// MARK: - DailySummaryCard

/// 日次サマリーカード
struct DailySummaryCard: View {
    let insight: DailyInsightResult?
    let morningScore: Int

    var body: some View {
        AsaLifeLogCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundStyle(.orange)
                    Text("今日のまとめ")
                        .font(.headline)
                    Spacer()
                }

                if let insight {
                    Text(insight.summaryText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // 朝活スコア
                    HStack {
                        StatRing(
                            value: Double(morningScore),
                            maxValue: 100,
                            label: "朝活スコア",
                            valueText: "\(morningScore)点",
                            ringColor: .orange,
                            size: 70
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(morningScoreLabel)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(morningScoreColor)

                            if !insight.suggestions.isEmpty {
                                ForEach(insight.suggestions.prefix(2), id: \.self) { suggestion in
                                    Label(suggestion, systemImage: "lightbulb")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } else {
                    Text("今日のデータを記録すると、インサイトが表示されます")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var morningScoreLabel: String {
        switch morningScore {
        case 80...: return "素晴らしい朝活！"
        case 60..<80: return "良い朝活でした"
        case 40..<60: return "まずまずの朝"
        case 20..<40: return "もう少し頑張ろう"
        default: return "朝活を始めましょう"
        }
    }

    private var morningScoreColor: Color {
        switch morningScore {
        case 80...: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }
}
