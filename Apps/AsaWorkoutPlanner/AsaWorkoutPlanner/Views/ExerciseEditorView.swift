//
//  ExerciseEditorView.swift
//  AsaWorkoutPlanner
//
//  エクササイズ編集画面
//  カスタムエクササイズの作成と編集
//

import SwiftUI
import AsaUIKit

struct ExerciseEditorView: View {
    // MARK: - Properties

    let plan: WorkoutPlan
    let exerciseToEdit: Exercise?
    @Bindable var viewModel: WorkoutPlannerViewModel
    @Environment(\.dismiss) private var dismiss

    // フォーム入力用の状態
    @State private var exerciseName = ""
    @State private var selectedCategory: ExerciseCategory = .chest
    @State private var selectedMuscles: Set<MuscleGroup> = []
    @State private var sets = 3
    @State private var reps = 10
    @State private var weight = ""
    @State private var restTime = 60
    @State private var duration = ""
    @State private var tempo = ""
    @State private var notes = ""
    @State private var videoURL = ""
    @State private var equipmentNeeded = ""
    @State private var instructions = ""
    @State private var tips = ""

    // UI状態
    @State private var isTimeBasedExercise = false

    init(plan: WorkoutPlan, exerciseToEdit: Exercise? = nil, viewModel: WorkoutPlannerViewModel) {
        self.plan = plan
        self.exerciseToEdit = exerciseToEdit
        self.viewModel = viewModel

        // 編集モードの場合は既存データで初期化
        if let exercise = exerciseToEdit {
            _exerciseName = State(initialValue: exercise.name)
            _selectedCategory = State(initialValue: exercise.category)
            _selectedMuscles = State(initialValue: Set(exercise.targetMuscles))
            _sets = State(initialValue: exercise.sets)
            _reps = State(initialValue: exercise.reps)
            _weight = State(initialValue: exercise.weight.map { "\(Int($0))" } ?? "")
            _restTime = State(initialValue: Int(exercise.restTime))
            _tempo = State(initialValue: exercise.tempo ?? "")
            _notes = State(initialValue: exercise.notes ?? "")
            _videoURL = State(initialValue: exercise.videoURL ?? "")
            _equipmentNeeded = State(initialValue: exercise.equipmentNeeded ?? "")
            _instructions = State(initialValue: exercise.instructions ?? "")
            _tips = State(initialValue: exercise.tips ?? "")

            if let dur = exercise.duration {
                _isTimeBasedExercise = State(initialValue: true)
                _duration = State(initialValue: "\(Int(dur / 60))")
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // 基本情報
                Section("基本情報") {
                    TextField("エクササイズ名", text: $exerciseName)

                    Picker("カテゴリー", selection: $selectedCategory) {
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }

                    NavigationLink {
                        MuscleGroupSelector(selectedMuscles: $selectedMuscles)
                    } label: {
                        HStack {
                            Text("ターゲット筋肉")
                            Spacer()
                            Text("\(selectedMuscles.count)個選択")
                                .foregroundColor(Color(AsaColors.mutedSage))
                        }
                    }

                    TextField("使用器具（オプション）", text: $equipmentNeeded)
                }

                // トレーニング設定
                Section("トレーニング設定") {
                    Toggle("時間ベースのエクササイズ", isOn: $isTimeBasedExercise)

                    HStack {
                        Text("セット数")
                        Spacer()
                        Stepper("\(sets)", value: $sets, in: 1...10)
                    }

                    if isTimeBasedExercise {
                        HStack {
                            Text("時間（分）")
                            Spacer()
                            TextField("分", text: $duration)
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                                .multilineTextAlignment(.trailing)
                        }
                    } else {
                        HStack {
                            Text("レップ数")
                            Spacer()
                            Stepper("\(reps)", value: $reps, in: 1...50)
                        }

                        TextField("重量（kg）- オプション", text: $weight)
                            .keyboardType(.decimalPad)

                        TextField("テンポ（例: 3-1-2-1）- オプション", text: $tempo)
                    }

                    HStack {
                        Text("休憩時間（秒）")
                        Spacer()
                        Stepper("\(restTime)", value: $restTime, in: 15...300, step: 15)
                    }
                }

                // 詳細情報
                Section("詳細情報") {
                    TextField("実施方法", text: $instructions, axis: .vertical)
                        .lineLimit(5...10)

                    TextField("ポイント・コツ", text: $tips, axis: .vertical)
                        .lineLimit(3...6)

                    TextField("メモ", text: $notes, axis: .vertical)
                        .lineLimit(2...5)

                    TextField("動画URL（オプション）", text: $videoURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }

                // プレビュー
                Section("プレビュー") {
                    ExercisePreviewCard(
                        name: exerciseName.isEmpty ? "エクササイズ名" : exerciseName,
                        category: selectedCategory,
                        sets: sets,
                        reps: reps,
                        weight: Double(weight),
                        duration: isTimeBasedExercise ? (Double(duration) ?? 0) * 60 : nil,
                        restTime: TimeInterval(restTime)
                    )
                }
            }
            .navigationTitle(exerciseToEdit == nil ? "新規エクササイズ" : "エクササイズ編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(exerciseToEdit == nil ? "追加" : "保存") {
                        saveExercise()
                    }
                    .disabled(exerciseName.isEmpty)
                }
            }
        }
    }

    // MARK: - Methods

    private func saveExercise() {
        if let existingExercise = exerciseToEdit {
            // 既存エクササイズを編集
            existingExercise.name = exerciseName
            existingExercise.category = selectedCategory
            existingExercise.targetMuscles = Array(selectedMuscles)
            existingExercise.sets = sets
            existingExercise.reps = reps
            existingExercise.weight = Double(weight)
            existingExercise.duration = isTimeBasedExercise ? (Double(duration) ?? 0) * 60 : nil
            existingExercise.restTime = TimeInterval(restTime)
            existingExercise.tempo = tempo.isEmpty ? nil : tempo
            existingExercise.notes = notes.isEmpty ? nil : notes
            existingExercise.videoURL = videoURL.isEmpty ? nil : videoURL
            existingExercise.equipmentNeeded = equipmentNeeded.isEmpty ? nil : equipmentNeeded
            existingExercise.instructions = instructions.isEmpty ? nil : instructions
            existingExercise.tips = tips.isEmpty ? nil : tips
            existingExercise.updatedAt = Date()
        } else {
            // 新規エクササイズを作成
            let exercise = Exercise(
                name: exerciseName,
                category: selectedCategory,
                sets: sets,
                reps: reps,
                restTime: TimeInterval(restTime)
            )

            exercise.targetMuscles = Array(selectedMuscles)
            exercise.weight = Double(weight)
            exercise.duration = isTimeBasedExercise ? (Double(duration) ?? 0) * 60 : nil
            exercise.tempo = tempo.isEmpty ? nil : tempo
            exercise.notes = notes.isEmpty ? nil : notes
            exercise.videoURL = videoURL.isEmpty ? nil : videoURL
            exercise.equipmentNeeded = equipmentNeeded.isEmpty ? nil : equipmentNeeded
            exercise.instructions = instructions.isEmpty ? nil : instructions
            exercise.tips = tips.isEmpty ? nil : tips

            plan.addExercise(exercise)
        }

        dismiss()
    }
}

// MARK: - Supporting Views

struct MuscleGroupSelector: View {
    @Binding var selectedMuscles: Set<MuscleGroup>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(musclesByCategory, id: \.category) { section in
                Section(section.category) {
                    ForEach(section.muscles, id: \.self) { muscle in
                        Button {
                            if selectedMuscles.contains(muscle) {
                                selectedMuscles.remove(muscle)
                            } else {
                                selectedMuscles.insert(muscle)
                            }
                        } label: {
                            HStack {
                                Text(muscle.rawValue)
                                    .foregroundColor(.primary)

                                Spacer()

                                if selectedMuscles.contains(muscle) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(AsaColors.coffeeBrown))
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("筋肉グループを選択")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完了") {
                    dismiss()
                }
            }
        }
    }

    private var musclesByCategory: [(category: String, muscles: [MuscleGroup])] {
        let categories: [String] = ["上半身", "体幹", "下半身"]

        return categories.map { category in
            let muscles = MuscleGroup.allCases.filter { $0.category == category }
            return (category, muscles)
        }
    }
}

struct ExercisePreviewCard: View {
    let name: String
    let category: ExerciseCategory
    let sets: Int
    let reps: Int
    let weight: Double?
    let duration: TimeInterval?
    let restTime: TimeInterval

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.headline)

                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(Color(category.color))

                            Text(category.rawValue)
                                .font(.caption)
                                .foregroundColor(Color(AsaColors.mutedSage))
                        }
                    }

                    Spacer()
                }

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("セット")
                            .font(.caption2)
                            .foregroundColor(Color(AsaColors.mutedSage))
                        Text("\(sets)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    if let duration = duration {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("時間")
                                .font(.caption2)
                                .foregroundColor(Color(AsaColors.mutedSage))
                            Text("\(Int(duration / 60))分")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("レップ")
                                .font(.caption2)
                                .foregroundColor(Color(AsaColors.mutedSage))
                            Text("\(reps)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }

                    if let weight = weight, weight > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("重量")
                                .font(.caption2)
                                .foregroundColor(Color(AsaColors.mutedSage))
                            Text("\(Int(weight))kg")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("休憩")
                            .font(.caption2)
                            .foregroundColor(Color(AsaColors.mutedSage))
                        Text("\(Int(restTime))秒")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
        }
    }
}
