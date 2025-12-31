//
//  PredictionCardView.swift
//  AsaSmartTodo
//
//  AI予測結果を表示するカード
//  リアルタイム予測で使用
//

import SwiftUI
import AsaUIKit

struct PredictionCardView: View {
    let prediction: PredictionResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(AsaColors.coffeeBrown)

                Text("AI予測")
                    .font(.headline)
                    .foregroundColor(AsaColors.coffeeBrown)

                Spacer()

                // 信頼度バッジ
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                    Text("\(prediction.confidencePercentage)%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(confidenceColor)
                .cornerRadius(12)
            }

            Divider()

            // 提案された優先度
            HStack {
                Text("提案優先度:")
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Text(prediction.suggestedPriority.icon)
                    Text(prediction.suggestedPriority.displayName)
                        .fontWeight(.bold)
                }
                .foregroundColor(prediction.suggestedPriority.color)

                Spacer()

                Text(prediction.confidenceText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 予測理由
            if !prediction.reasons.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("理由:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(prediction.reasons) { reason in
                        HStack(spacing: 6) {
                            Text(reason.emoji)
                            Text(reason.description)
                                .font(.caption)
                        }
                    }
                }
            }

            // タップして採用のヒント
            HStack {
                Spacer()
                Text("タップして採用")
                    .font(.caption2)
                    .foregroundColor(AsaColors.mutedSage)
                    .italic()
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding()
        .background(AsaColors.softCream.opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AsaColors.coffeeBrown.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }

    // MARK: - Helper Properties

    private var confidenceColor: Color {
        switch prediction.confidenceScore {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return AsaColors.coffeeBrown
        case 0.4..<0.6:
            return .orange
        default:
            return .gray
        }
    }
}
