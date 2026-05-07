import SwiftUI
import AsaPapaHubKit
import AsaUIKit

// MARK: - 朝活スコアカード

/// ダッシュボードのメイン朝活スコア表示
struct MorningScoreCard: View {
    let score: Int
    let routine: MorningRoutine?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("朝活スコア")
                        .font(.headline)
                        .foregroundStyle(AsaColors.darkSlate)

                    Text(scoreMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                ScoreRing(
                    progress: Double(score) / 100.0,
                    lineWidth: 10,
                    size: 80,
                    label: "点"
                )
            }

            // ルーティン進捗バー
            if let routine, !routine.items.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("今日のルーティン")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(routine.completedItemsCount)/\(routine.items.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    ProgressView(value: routine.completionRate)
                        .tint(AsaColors.coffeeBrown)
                }
            }
        }
        .hubFeaturedCardStyle()
    }

    // MARK: - Private

    private var scoreMessage: String {
        switch score {
        case 90...100: "素晴らしい朝です！"
        case 70..<90: "いい調子ですね！"
        case 50..<70: "もう少し頑張りましょう"
        default: "朝活を始めましょう"
        }
    }
}
