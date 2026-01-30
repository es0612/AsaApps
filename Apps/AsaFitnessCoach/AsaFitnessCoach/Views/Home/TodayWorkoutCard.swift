//
//  TodayWorkoutCard.swift
//  AsaFitnessCoach
//
//  今日のワークアウトカード
//

import SwiftUI

struct TodayWorkoutCard: View {
    // MARK: - Properties

    let plan: WorkoutPlan
    let onStart: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: plan.category.icon)
                    .font(.title2)
                    .foregroundStyle(Color(plan.category.color))

                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(.headline)

                    HStack(spacing: 8) {
                        Label(plan.displayEstimatedDuration, systemImage: "clock")
                        Label("\(plan.totalExercises) 種目", systemImage: "figure.strengthtraining.traditional")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if plan.isAIGenerated {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                }
            }

            HStack(spacing: 8) {
                ForEach(plan.scheduledDays.prefix(7), id: \.self) { day in
                    Text(day.shortName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(day == WeekDay.today ? .white : .secondary)
                        .frame(width: 24, height: 24)
                        .background(day == WeekDay.today ? Color.accentColor : Color.clear)
                        .clipShape(Circle())
                }
            }

            Button(action: onStart) {
                Label("開始", systemImage: "play.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Preview

#Preview {
    let plan = WorkoutPlan(
        name: "筋力アッププラン",
        description: "上半身を鍛えるワークアウト",
        difficulty: .intermediate,
        category: .strength
    )
    plan.scheduledDays = [.monday, .wednesday, .friday]
    plan.estimatedDuration = 45
    plan.isAIGenerated = true

    return TodayWorkoutCard(plan: plan, onStart: {})
        .padding()
}
