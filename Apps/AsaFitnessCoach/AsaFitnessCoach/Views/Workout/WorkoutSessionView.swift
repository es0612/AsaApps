//
//  WorkoutSessionView.swift
//  AsaFitnessCoach
//
//  ワークアウト実行画面
//

import SwiftUI

struct WorkoutSessionView: View {
    // MARK: - Properties

    @Bindable var viewModel: FitnessCoachViewModel
    let plan: WorkoutPlan

    @Environment(\.dismiss) private var dismiss

    @State private var workoutVM: WorkoutViewModel?
    @State private var showExitConfirmation = false
    @State private var showCompletionView = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if let vm = workoutVM {
                    if vm.isCompleted {
                        WorkoutCompletionView(
                            workoutVM: vm,
                            onDismiss: {
                                viewModel.completeWorkoutSession(vm.session)
                                dismiss()
                            }
                        )
                    } else if vm.isResting {
                        RestTimerView(workoutVM: vm)
                    } else {
                        ActiveWorkoutView(workoutVM: vm)
                    }
                } else {
                    ProgressView("ワークアウトを準備中...")
                }
            }
            .navigationTitle(plan.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("終了") {
                        showExitConfirmation = true
                    }
                }

                if let vm = workoutVM, !vm.isCompleted {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            if vm.isPaused {
                                vm.resumeWorkout()
                            } else {
                                vm.pauseWorkout()
                            }
                        } label: {
                            Image(systemName: vm.isPaused ? "play.fill" : "pause.fill")
                        }
                    }
                }
            }
            .interactiveDismissDisabled()
            .confirmationDialog(
                "ワークアウトを終了しますか？",
                isPresented: $showExitConfirmation,
                titleVisibility: .visible
            ) {
                Button("保存して終了") {
                    workoutVM?.finishWorkout()
                }
                Button("終了（保存しない）", role: .destructive) {
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            }
            .onAppear {
                setupWorkout()
            }
        }
    }

    // MARK: - Methods

    private func setupWorkout() {
        let session = viewModel.startWorkoutSession(for: plan)
        workoutVM = WorkoutViewModel(session: session, plan: plan)
        workoutVM?.startWorkout()
    }
}

// MARK: - Active Workout View

struct ActiveWorkoutView: View {
    @Bindable var workoutVM: WorkoutViewModel

    @State private var reps: Int = 10
    @State private var weight: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // 進捗ヘッダー
            progressHeader

            ScrollView {
                VStack(spacing: 24) {
                    // 現在のエクササイズ
                    if let exercise = workoutVM.currentPlanExercise {
                        exerciseCard(exercise)
                    }

                    // セット入力
                    setInputSection

                    // ガイド
                    if let exercise = workoutVM.currentPlanExercise,
                       let instructions = exercise.instructions {
                        guideSection(instructions)
                    }
                }
                .padding()
            }

            // 完了ボタン
            completeSetButton
        }
        .onAppear {
            if let exercise = workoutVM.currentPlanExercise {
                reps = exercise.reps
                if let w = exercise.weight {
                    weight = String(format: "%.1f", w)
                }
            }
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 8) {
            // 進捗バー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))

                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * workoutVM.progress)
                }
            }
            .frame(height: 4)

            HStack {
                // 経過時間
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text(workoutVM.elapsedTimeString)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Spacer()

                // 進捗
                Text("\(workoutVM.completedSets)/\(workoutVM.totalSets) セット")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                // エクササイズ番号
                Text("\(workoutVM.currentExerciseIndex + 1)/\(workoutVM.totalExercises)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private func exerciseCard(_ exercise: Exercise) -> some View {
        VStack(spacing: 16) {
            // カテゴリアイコン
            Image(systemName: exercise.category.icon)
                .font(.system(size: 50))
                .foregroundStyle(Color(exercise.category.color))

            // エクササイズ名
            Text(exercise.name)
                .font(.title2)
                .fontWeight(.bold)

            // ターゲット
            HStack(spacing: 16) {
                VStack {
                    Text("\(exercise.sets)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("セット")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if exercise.isTimeBasedExercise {
                    VStack {
                        Text(exercise.displayDuration)
                            .font(.title)
                            .fontWeight(.bold)
                        Text("時間")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    VStack {
                        Text("\(exercise.reps)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("レップ")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let weight = exercise.weight {
                    VStack {
                        Text("\(Int(weight))kg")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("重量")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // 現在のセット
            Text("セット \(workoutVM.currentSetIndex + 1)")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var setInputSection: some View {
        VStack(spacing: 16) {
            Text("実績を記録")
                .font(.headline)

            HStack(spacing: 20) {
                // レップ数
                VStack(spacing: 8) {
                    Text("レップ")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button {
                            if reps > 1 { reps -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                        }

                        Text("\(reps)")
                            .font(.title)
                            .fontWeight(.bold)
                            .frame(width: 50)

                        Button {
                            reps += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }

                Divider()
                    .frame(height: 60)

                // 重量
                VStack(spacing: 8) {
                    Text("重量 (kg)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("0", text: $weight)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func guideSection(_ instructions: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("やり方")
                .font(.headline)

            Text(instructions)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var completeSetButton: some View {
        VStack(spacing: 8) {
            Button {
                let weightValue = Double(weight)
                workoutVM.completeSet(reps: reps, weight: weightValue)
            } label: {
                Text("セット完了")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                workoutVM.skipSet()
            } label: {
                Text("スキップ")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview

#Preview {
    let plan = WorkoutPlan(
        name: "テストプラン",
        description: "テスト用のワークアウトプラン",
        difficulty: .intermediate,
        category: .strength
    )

    return WorkoutSessionView(viewModel: FitnessCoachViewModel(), plan: plan)
}
