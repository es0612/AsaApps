//
//  AIRecommendationCard.swift
//  AsaFitnessCoach
//
//  AI提案カード
//

import SwiftUI

struct AIRecommendationCard: View {
    // MARK: - Properties

    let recommendation: AIRecommendation
    let onAccept: () -> Void

    @State private var showDetails = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.planName)
                        .font(.headline)

                    Text(recommendation.planDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // 信頼度バッジ
                ConfidenceBadge(
                    confidence: recommendation.confidence,
                    text: recommendation.confidenceText
                )
            }

            // 基本情報
            HStack(spacing: 16) {
                InfoChip(
                    icon: recommendation.category.icon,
                    text: recommendation.category.rawValue
                )

                InfoChip(
                    icon: "clock",
                    text: "\(recommendation.estimatedDuration)分"
                )

                InfoChip(
                    icon: "figure.strengthtraining.traditional",
                    text: "\(recommendation.exercises.count)種目"
                )
            }

            // 提案理由
            if showDetails {
                VStack(alignment: .leading, spacing: 8) {
                    Text("提案理由")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(recommendation.reasons.prefix(4)) { reason in
                        ReasonRow(reason: reason)
                    }
                }
                .padding(.top, 8)

                // エクササイズリスト
                VStack(alignment: .leading, spacing: 8) {
                    Text("エクササイズ")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(recommendation.exercises) { exercise in
                        ExercisePreviewRow(exercise: exercise)
                    }
                }
                .padding(.top, 8)
            }

            // アクションボタン
            HStack(spacing: 12) {
                Button {
                    withAnimation {
                        showDetails.toggle()
                    }
                } label: {
                    Label(showDetails ? "閉じる" : "詳細を見る", systemImage: showDetails ? "chevron.up" : "chevron.down")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onAccept) {
                    Label("プランを作成", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.purple)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Supporting Views

struct ConfidenceBadge: View {
    let confidence: Double
    let text: String

    var color: Color {
        switch confidence {
        case 0.75...: return .green
        case 0.5..<0.75: return .yellow
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "chart.bar.fill")
                .font(.caption2)

            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct InfoChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}

struct ReasonRow: View {
    let reason: RecommendationReason

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: reason.factor.icon)
                .font(.caption)
                .foregroundStyle(.purple)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(reason.factor.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)

                    Spacer()

                    Text(reason.displayScore)
                        .font(.caption)
                        .foregroundStyle(scoreColor(reason.score))
                }

                Text(reason.explanation)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0.8...: return .green
        case 0.6..<0.8: return .yellow
        default: return .orange
        }
    }
}

struct ExercisePreviewRow: View {
    let exercise: RecommendedExercise

    var body: some View {
        HStack {
            Image(systemName: exercise.category.icon)
                .font(.caption)
                .foregroundStyle(Color(exercise.category.color))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.caption)
                    .fontWeight(.medium)

                Text("\(exercise.suggestedSets)セット × \(exercise.suggestedReps)レップ")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // マッチスコア
            Text("\(Int(exercise.matchScore * 100))%")
                .font(.caption2)
                .foregroundStyle(.purple)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    let recommendation = AIRecommendation(
        planName: "筋力アッププラン - 30分",
        planDescription: "あなたの目標「筋力アップ」に最適化されたプランです",
        exercises: [
            RecommendedExercise(
                name: "ベンチプレス",
                category: .chest,
                targetMuscles: [.pectoralisMajor],
                suggestedSets: 4,
                suggestedReps: 8,
                suggestedWeight: nil,
                suggestedDuration: nil,
                restTime: 90,
                instructions: nil,
                matchScore: 0.92
            ),
            RecommendedExercise(
                name: "スクワット",
                category: .legs,
                targetMuscles: [.quadriceps],
                suggestedSets: 4,
                suggestedReps: 10,
                suggestedWeight: nil,
                suggestedDuration: nil,
                restTime: 90,
                instructions: nil,
                matchScore: 0.88
            )
        ],
        category: .strength,
        difficulty: .intermediate,
        estimatedDuration: 30,
        confidence: 0.85,
        reasons: [
            RecommendationReason(
                factor: .goalAlignment,
                score: 0.92,
                explanation: "「筋力アップ」の目標に非常に適しています"
            ),
            RecommendationReason(
                factor: .fitnessLevel,
                score: 0.85,
                explanation: "中級者レベルに最適な難易度です"
            )
        ]
    )

    return AIRecommendationCard(recommendation: recommendation, onAccept: {})
        .padding()
}
