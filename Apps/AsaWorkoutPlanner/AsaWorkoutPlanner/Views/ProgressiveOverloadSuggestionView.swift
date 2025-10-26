//
//  ProgressiveOverloadSuggestionView.swift
//  AsaWorkoutPlanner
//
//  プログレッシブ・オーバーロード提案表示
//

import SwiftUI
import AsaUIKit

struct ProgressiveOverloadSuggestionView: View {
    // MARK: - Properties

    let suggestions: [OverloadSuggestion]
    let onApply: (OverloadSuggestion) -> Void

    // MARK: - Body

    var body: some View {
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(Color(AsaColors.coffeeBrown))
                    Text("重量増加の提案")
                        .font(.headline)

                    Spacer()

                    Image(systemName: "info.circle")
                        .foregroundColor(Color(AsaColors.mutedSage))
                        .help("過去のパフォーマンスに基づいた提案です")
                }

                ForEach(Array(suggestions.enumerated()), id: \.offset) { _, suggestion in
                    suggestionCard(suggestion)
                }
            }
        }
    }

    // MARK: - Components

    private func suggestionCard(_ suggestion: OverloadSuggestion) -> some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                // エクササイズ名と信頼度
                HStack {
                    Text(suggestion.exerciseName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    confidenceBadge(suggestion.confidence)
                }

                // 現在の重量と提案
                HStack(alignment: .bottom, spacing: 20) {
                    // 現在の重量
                    VStack(alignment: .leading, spacing: 4) {
                        Text("現在")
                            .font(.caption)
                            .foregroundColor(Color(AsaColors.mutedSage))

                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text("\(Int(suggestion.currentWeight))")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("kg")
                                .font(.caption)
                                .foregroundColor(Color(AsaColors.mutedSage))
                        }
                    }

                    // 矢印
                    Image(systemName: "arrow.right")
                        .foregroundColor(Color(AsaColors.coffeeBrown))
                        .font(.title3)

                    // 提案される重量
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("提案")
                                .font(.caption)
                                .foregroundColor(Color(AsaColors.coffeeBrown))

                            if suggestion.increasePercentage > 0 {
                                Text("+\(String(format: "%.1f", suggestion.increasePercentage))%")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(AsaColors.coffeeBrown))
                                    .cornerRadius(4)
                            }
                        }

                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text("\(Int(suggestion.suggestedWeight))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(AsaColors.coffeeBrown))
                            Text("kg")
                                .font(.caption)
                                .foregroundColor(Color(AsaColors.mutedSage))
                        }
                    }

                    Spacer()
                }

                // 理由
                Text(suggestion.reason)
                    .font(.caption)
                    .foregroundColor(Color(AsaColors.mutedSage))
                    .fixedSize(horizontal: false, vertical: true)

                // 適用ボタン
                if suggestion.suggestedWeight != suggestion.currentWeight {
                    Button {
                        onApply(suggestion)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("この提案を適用")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(AsaColors.coffeeBrown))
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
    }

    private func confidenceBadge(_ confidence: OverloadSuggestion.ConfidenceLevel) -> some View {
        HStack(spacing: 4) {
            switch confidence {
            case .high:
                Image(systemName: "star.fill")
                    .foregroundColor(.green)
            case .medium:
                Image(systemName: "star.leadinghalf.filled")
                    .foregroundColor(.orange)
            case .low:
                Image(systemName: "star")
                    .foregroundColor(.gray)
            }

            Text(confidence.description)
                .font(.caption2)
                .foregroundColor(Color(AsaColors.mutedSage))
        }
    }
}

// MARK: - Preview

#Preview {
    let suggestions = [
        OverloadSuggestion(
            exerciseName: "ベンチプレス",
            currentWeight: 60.0,
            suggestedWeight: 62.5,
            increasePercentage: 4.2,
            reason: "完了率100%、フォーム良好。次のレベルへ進みましょう",
            confidence: .high
        ),
        OverloadSuggestion(
            exerciseName: "スクワット",
            currentWeight: 80.0,
            suggestedWeight: 82.5,
            increasePercentage: 3.1,
            reason: "安定したパフォーマンス。徐々に負荷を増やしましょう",
            confidence: .medium
        )
    ]

    return ScrollView {
        ProgressiveOverloadSuggestionView(suggestions: suggestions) { suggestion in
            print("提案を適用: \(suggestion.exerciseName)")
        }
        .padding()
    }
}
