//
//  ActiveWorkoutSessionView.swift
//  AsaWorkoutPlanner
//
//  アクティブワークアウトセッション実行画面
//  エクササイズごとのセット管理、タイマー、進捗トラッキング
//

import SwiftUI
import AsaUIKit

struct ActiveWorkoutSessionView: View {
    // MARK: - Properties

    @Bindable var viewModel: WorkoutPlannerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentExerciseIndex = 0
    @State private var showingRestTimer = false
    @State private var restTimeDuration: TimeInterval = 60

    // セット入力用の状態
    @State private var repsInput: String = ""
    @State private var weightInput: String = ""
    @State private var showingFormQuality = false
    @State private var selectedFormQuality: FormQuality?
    @State private var selectedDifficulty: ExerciseDifficulty?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        if let session = viewModel.currentSession {
                            // セッション情報ヘッダー
                            sessionHeader(session)

                            // 進捗バー
                            progressSection(session)

                            // 現在のエクササイズ
                            if !session.completedExercises.isEmpty {
                                currentExerciseCard(session)
                            }

                            // エクササイズリスト
                            exerciseListSection(session)

                            // アクションボタン
                            actionButtons(session)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("ワークアウト実行中")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        cancelSession()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingRestTimer) {
                RestTimerView(
                    initialTime: restTimeDuration,
                    exerciseName: getCurrentExercise()?.exerciseName
                ) {
                    // タイマー完了時の処理
                    print("休憩完了")
                }
            }
            .onAppear {
                initializeInputs()
            }
        }
    }

    // MARK: - Components

    private func sessionHeader(_ session: WorkoutSession) -> some View {
        AsaCard {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.workoutPlan?.name ?? "ワークアウト")
                            .font(.title3)
                            .fontWeight(.bold)

                        Text("開始時刻: \(session.startTime.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(Color(AsaColors.mutedSage))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(session.displayDuration)
                            .font(.title2)
                            .fontWeight(.bold)
                            .monospacedDigit()

                        if session.isPaused {
                            Text("一時停止中")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }

                HStack(spacing: 20) {
                    StatItem(
                        label: "完了セット",
                        value: "\(completedSetsCount(session))/\(totalSetsCount(session))"
                    )

                    StatItem(
                        label: "消費カロリー",
                        value: "\(Int(session.totalCaloriesBurned)) kcal"
                    )

                    StatItem(
                        label: "総ボリューム",
                        value: String(format: "%.0f kg", session.totalVolume)
                    )
                }
            }
            .padding()
        }
    }

    private func progressSection(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("進捗")
                    .font(.headline)

                Spacer()

                Text("\(session.completionPercentage)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            SwiftUI.ProgressView(value: session.completionRate)
                .tint(Color(AsaColors.coffeeBrown))
                .scaleEffect(x: 1, y: 2)
        }
    }

    private func currentExerciseCard(_ session: WorkoutSession) -> some View {
        Group {
            if currentExerciseIndex < session.completedExercises.count {
                let completedExercise = session.completedExercises[currentExerciseIndex]

                AsaCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(completedExercise.exerciseName)
                                    .font(.title2)
                                    .fontWeight(.bold)

                                HStack {
                                    Image(systemName: completedExercise.category.icon)
                                        .foregroundColor(Color(completedExercise.category.color))

                                    Text(completedExercise.category.rawValue)
                                        .font(.caption)
                                        .foregroundColor(Color(AsaColors.mutedSage))
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("セット \(completedExercise.completedSets + 1)/\(completedExercise.plannedSets)")
                                    .font(.headline)
                                    .foregroundColor(Color(AsaColors.coffeeBrown))
                            }
                        }

                        Divider()

                        // 目標値表示
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("目標レップ")
                                    .font(.caption)
                                    .foregroundColor(Color(AsaColors.mutedSage))
                                Text("\(completedExercise.plannedReps)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }

                            if let weight = completedExercise.weight {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("目標重量")
                                        .font(.caption)
                                        .foregroundColor(Color(AsaColors.mutedSage))
                                    Text("\(Int(weight)) kg")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                            }

                            Spacer()
                        }

                        // 入力フィールド
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("実際のレップ数")
                                        .font(.caption)
                                        .foregroundColor(Color(AsaColors.mutedSage))

                                    TextField("レップ数", text: $repsInput)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(.roundedBorder)
                                }

                                if completedExercise.weight != nil {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("実際の重量 (kg)")
                                            .font(.caption)
                                            .foregroundColor(Color(AsaColors.mutedSage))

                                        TextField("重量", text: $weightInput)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }

                            AsaButton(
                                title: "セット完了",
                                action: {
                                    completeCurrentSet(completedExercise)
                                },
                                color: AsaColors.coffeeBrown
                            )
                            .disabled(repsInput.isEmpty || (completedExercise.weight != nil && weightInput.isEmpty))
                        }

                        // 前セットの記録（あれば）
                        if !completedExercise.actualReps.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("前セットの記録")
                                    .font(.caption)
                                    .foregroundColor(Color(AsaColors.mutedSage))

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Array(completedExercise.actualReps.enumerated()), id: \.offset) { index, reps in
                                            VStack(spacing: 4) {
                                                Text("セット\(index + 1)")
                                                    .font(.caption2)
                                                    .foregroundColor(Color(AsaColors.mutedSage))

                                                HStack(spacing: 4) {
                                                    Text("\(reps)回")
                                                        .font(.caption)
                                                        .fontWeight(.medium)

                                                    if index < completedExercise.actualWeight.count {
                                                        Text("×\(Int(completedExercise.actualWeight[index]))kg")
                                                            .font(.caption)
                                                            .fontWeight(.medium)
                                                    }
                                                }
                                            }
                                            .padding(8)
                                            .background(Color(AsaColors.softCream).opacity(0.3))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private func exerciseListSection(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("エクササイズ一覧")
                .font(.headline)

            ForEach(Array(session.completedExercises.enumerated()), id: \.element.id) { index, exercise in
                ExerciseRow(
                    exercise: exercise,
                    isCurrent: index == currentExerciseIndex,
                    onTap: {
                        currentExerciseIndex = index
                        initializeInputs()
                    }
                )
            }
        }
    }

    private func actionButtons(_ session: WorkoutSession) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                AsaButton(
                    title: session.isPaused ? "再開" : "一時停止",
                    action: {
                        if session.isPaused {
                            viewModel.resumeSession()
                        } else {
                            viewModel.pauseSession()
                        }
                    },
                    color: AsaColors.softCream
                )

                AsaButton(
                    title: "完了",
                    action: {
                        completeSession()
                    },
                    color: AsaColors.coffeeBrown
                )
            }

            if let session = viewModel.currentSession {
                Text("\(session.completedExercises.filter { $0.isCompleted }.count)/\(session.completedExercises.count) エクササイズ完了")
                    .font(.caption)
                    .foregroundColor(Color(AsaColors.mutedSage))
            }
        }
    }

    // MARK: - Helper Methods

    private func completedSetsCount(_ session: WorkoutSession) -> Int {
        session.completedExercises.reduce(0) { $0 + $1.completedSets }
    }

    private func totalSetsCount(_ session: WorkoutSession) -> Int {
        session.completedExercises.reduce(0) { $0 + $1.plannedSets }
    }

    private func getCurrentExercise() -> CompletedExercise? {
        guard let session = viewModel.currentSession,
              currentExerciseIndex < session.completedExercises.count else {
            return nil
        }
        return session.completedExercises[currentExerciseIndex]
    }

    private func getCurrentRestTime() -> TimeInterval {
        guard let session = viewModel.currentSession,
              let plan = session.workoutPlan,
              currentExerciseIndex < plan.exercises.count else {
            return 60  // デフォルト休憩時間
        }
        return plan.exercises[currentExerciseIndex].restTime
    }

    private func initializeInputs() {
        guard let exercise = getCurrentExercise() else { return }

        repsInput = "\(exercise.plannedReps)"
        if let weight = exercise.weight {
            weightInput = "\(Int(weight))"
        } else {
            weightInput = ""
        }
    }

    private func completeCurrentSet(_ exercise: CompletedExercise) {
        guard let reps = Int(repsInput) else { return }

        let weight: Double? = if exercise.weight != nil, let w = Double(weightInput) {
            w
        } else {
            nil
        }

        // セットを完了
        exercise.completeSet(reps: reps, weight: weight)

        // レストタイマーを開始（最後のセットでない場合）
        if exercise.completedSets < exercise.plannedSets {
            startRestTimer(duration: getCurrentRestTime())
        } else {
            // エクササイズ完了時の評価ダイアログ
            showingFormQuality = true

            // 次のエクササイズに移動
            if currentExerciseIndex < (viewModel.currentSession?.completedExercises.count ?? 0) - 1 {
                currentExerciseIndex += 1
                initializeInputs()
            }
        }

        // 入力フィールドをリセット
        initializeInputs()
    }

    private func startRestTimer(duration: TimeInterval) {
        restTimeDuration = duration
        showingRestTimer = true
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func completeSession() {
        viewModel.completeSession()
        dismiss()
    }

    private func cancelSession() {
        viewModel.cancelSession()
        dismiss()
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(Color(AsaColors.mutedSage))

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

struct ExerciseRow: View {
    let exercise: CompletedExercise
    let isCurrent: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            AsaCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.exerciseName)
                            .font(.subheadline)
                            .fontWeight(isCurrent ? .semibold : .regular)
                            .foregroundColor(isCurrent ? Color(AsaColors.coffeeBrown) : .primary)

                        HStack(spacing: 8) {
                            Label("\(exercise.completedSets)/\(exercise.plannedSets) セット", systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundColor(Color(AsaColors.mutedSage))

                            if exercise.isCompleted {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                    }

                    Spacer()

                    if isCurrent {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(Color(AsaColors.coffeeBrown))
                    }
                }
                .padding()
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCurrent ? Color(AsaColors.coffeeBrown) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
