//
//  WeeklyHighlightCard.swift
//  AsaHealthDashboard
//
//  週間ハイライトカード
//

import SwiftUI
import AsaUIKit

struct WeeklyHighlightCard: View {
    let highlights: WeeklyHighlights

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("週間ハイライト")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    Spacer()

                    Text("総合達成率: \(Int(highlights.overallAchievementRate))%")
                        .font(.caption)
                        .foregroundColor(AsaColors.coffeeBrown)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AsaColors.softCream)
                        .cornerRadius(8)
                }

                // メイン統計
                HStack(spacing: 16) {
                    WeeklyStatItem(
                        icon: "figure.walk",
                        title: "総歩数",
                        value: highlights.formattedTotalSteps,
                        unit: "歩",
                        color: HealthCategory.steps.color
                    )

                    WeeklyStatItem(
                        icon: "flame",
                        title: "総カロリー",
                        value: String(format: "%.0f", highlights.totalCalories),
                        unit: "kcal",
                        color: HealthCategory.calories.color
                    )
                }

                Divider()

                // 平均統計
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    AverageStatItem(
                        title: "平均歩数",
                        value: String(format: "%.0f", highlights.averageSteps),
                        unit: "歩/日"
                    )

                    AverageStatItem(
                        title: "平均距離",
                        value: String(format: "%.1f", highlights.averageDistance),
                        unit: "km/日"
                    )

                    AverageStatItem(
                        title: "平均睡眠",
                        value: String(format: "%.1f", highlights.averageSleep),
                        unit: "時間/日"
                    )
                }

                // 目標達成日数
                VStack(alignment: .leading, spacing: 8) {
                    Text("目標達成日数（過去7日間）")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)

                    HStack(spacing: 8) {
                        ForEach(HealthCategory.allCases) { category in
                            let achievedDays = highlights.achievedDays[category] ?? 0
                            AchievedDaysIndicator(
                                category: category,
                                achievedDays: achievedDays
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - 週間統計アイテム

struct WeeklyStatItem: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(AsaColors.darkSlate)

                Text(unit)
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 平均統計アイテム

struct AverageStatItem: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            Text(unit)
                .font(.system(size: 10))
                .foregroundColor(AsaColors.mutedSage)

            Text(title)
                .font(.system(size: 10))
                .foregroundColor(AsaColors.mutedSage)
        }
    }
}

// MARK: - 達成日数インジケーター

struct AchievedDaysIndicator: View {
    let category: HealthCategory
    let achievedDays: Int

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption)
                .foregroundColor(category.color)

            Text("\(achievedDays)/7")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(achievedDays >= 5 ? .green : AsaColors.darkSlate)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    WeeklyHighlightCard(
        highlights: WeeklyHighlights(
            totalSteps: 52000,
            totalDistance: 35.5,
            totalCalories: 2800,
            totalExerciseTime: 180,
            averageSleep: 7.2,
            achievedDays: [
                .steps: 5,
                .distance: 4,
                .calories: 6,
                .exerciseTime: 3,
                .sleep: 5
            ]
        )
    )
    .padding()
}
