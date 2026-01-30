//
//  RestTimerView.swift
//  AsaFitnessCoach
//
//  休憩タイマー画面
//

import SwiftUI

struct RestTimerView: View {
    // MARK: - Properties

    @Bindable var workoutVM: WorkoutViewModel

    // MARK: - Body

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // 休憩中ラベル
            Text("休憩中")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            // タイマー
            ZStack {
                // 背景円
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 250, height: 250)

                // 進捗円
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                // 時間表示
                VStack(spacing: 8) {
                    Text(workoutVM.restTimeRemainingString)
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .monospacedDigit()

                    Text("残り時間")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // 次のエクササイズ
            if let nextExercise = workoutVM.currentPlanExercise {
                VStack(spacing: 8) {
                    Text("次のセット")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        Image(systemName: nextExercise.category.icon)
                            .foregroundStyle(Color(nextExercise.category.color))

                        Text(nextExercise.name)
                            .font(.headline)
                    }

                    Text("セット \(workoutVM.currentSetIndex + 1) / \(nextExercise.sets)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()

            // アクションボタン
            VStack(spacing: 12) {
                Button {
                    workoutVM.skipRest()
                } label: {
                    Text("スキップ")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // 休憩延長ボタン
                HStack(spacing: 12) {
                    ExtendRestButton(seconds: 15) {
                        extendRest(by: 15)
                    }

                    ExtendRestButton(seconds: 30) {
                        extendRest(by: 30)
                    }

                    ExtendRestButton(seconds: 60) {
                        extendRest(by: 60)
                    }
                }
            }
            .padding()
        }
        .padding()
    }

    // MARK: - Computed Properties

    private var progress: Double {
        guard let exercise = workoutVM.currentPlanExercise else { return 0 }
        let totalRest = exercise.restTime
        guard totalRest > 0 else { return 0 }
        return workoutVM.restTimeRemaining / totalRest
    }

    // MARK: - Methods

    private func extendRest(by seconds: Int) {
        workoutVM.restTimeRemaining += Double(seconds)
    }
}

// MARK: - Extend Rest Button

struct ExtendRestButton: View {
    let seconds: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("+\(seconds)秒")
                .font(.subheadline)
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview {
    let session = WorkoutSession(planName: "テストプラン")
    let plan = WorkoutPlan(name: "テストプラン")
    let vm = WorkoutViewModel(session: session, plan: plan)

    return RestTimerView(workoutVM: vm)
}
