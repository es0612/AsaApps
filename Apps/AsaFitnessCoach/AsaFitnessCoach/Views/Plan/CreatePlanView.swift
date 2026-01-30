//
//  CreatePlanView.swift
//  AsaFitnessCoach
//
//  プラン作成画面
//

import SwiftUI

struct CreatePlanView: View {
    // MARK: - Properties

    @Bindable var viewModel: FitnessCoachViewModel
    var editingPlan: WorkoutPlan?

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var planDescription = ""
    @State private var category: WorkoutCategory = .general
    @State private var difficulty: Difficulty = .intermediate
    @State private var scheduledDays: Set<WeekDay> = []
    @State private var exercises: [Exercise] = []
    @State private var showExerciseLibrary = false

    private var isEditing: Bool {
        editingPlan != nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // 基本情報
                basicInfoSection

                // スケジュール
                scheduleSection

                // エクササイズ
                exercisesSection
            }
            .navigationTitle(isEditing ? "プラン編集" : "新規プラン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        savePlan()
                    }
                    .disabled(name.isEmpty || exercises.isEmpty)
                }
            }
            .sheet(isPresented: $showExerciseLibrary) {
                ExerciseLibraryView(selectedExercises: $exercises)
            }
            .onAppear {
                if let plan = editingPlan {
                    loadPlan(plan)
                }
            }
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        Section("基本情報") {
            TextField("プラン名", text: $name)

            TextField("説明（オプション）", text: $planDescription)

            Picker("カテゴリ", selection: $category) {
                ForEach(WorkoutCategory.allCases, id: \.self) { cat in
                    Label(cat.rawValue, systemImage: cat.icon)
                        .tag(cat)
                }
            }

            Picker("難易度", selection: $difficulty) {
                ForEach(Difficulty.allCases, id: \.self) { diff in
                    Text(diff.rawValue).tag(diff)
                }
            }
        }
    }

    private var scheduleSection: some View {
        Section("スケジュール") {
            HStack(spacing: 8) {
                ForEach(WeekDay.allCases, id: \.self) { day in
                    let isSelected = scheduledDays.contains(day)
                    Button {
                        if isSelected {
                            scheduledDays.remove(day)
                        } else {
                            scheduledDays.insert(day)
                        }
                    } label: {
                        Text(day.shortName)
                            .font(.caption)
                            .fontWeight(isSelected ? .bold : .regular)
                            .foregroundStyle(isSelected ? .white : .primary)
                            .frame(width: 36, height: 36)
                            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var exercisesSection: some View {
        Section {
            if exercises.isEmpty {
                Text("エクササイズを追加してください")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(exercises) { exercise in
                    ExerciseEditRow(exercise: exercise)
                }
                .onDelete(perform: deleteExercise)
                .onMove(perform: moveExercise)
            }

            Button {
                showExerciseLibrary = true
            } label: {
                Label("エクササイズを追加", systemImage: "plus.circle")
            }
        } header: {
            HStack {
                Text("エクササイズ")
                Spacer()
                if !exercises.isEmpty {
                    EditButton()
                }
            }
        }
    }

    // MARK: - Methods

    private func loadPlan(_ plan: WorkoutPlan) {
        name = plan.name
        planDescription = plan.planDescription
        category = plan.category
        difficulty = plan.difficulty
        scheduledDays = Set(plan.scheduledDays)
        exercises = plan.exercises.sorted { $0.order < $1.order }
    }

    private func savePlan() {
        if let plan = editingPlan {
            // 更新
            plan.name = name
            plan.planDescription = planDescription
            plan.category = category
            plan.difficulty = difficulty
            plan.scheduledDays = Array(scheduledDays)
            plan.exercises = exercises
            plan.updateEstimatedDuration()
            plan.updatedAt = Date()
        } else {
            // 新規作成
            let plan = WorkoutPlan(
                name: name,
                description: planDescription,
                difficulty: difficulty,
                category: category
            )
            plan.scheduledDays = Array(scheduledDays)

            for (index, exercise) in exercises.enumerated() {
                exercise.order = index
                plan.addExercise(exercise)
            }

            viewModel.createPlan(plan)
        }

        dismiss()
    }

    private func deleteExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }

    private func moveExercise(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
        for (index, exercise) in exercises.enumerated() {
            exercise.order = index
        }
    }
}

// MARK: - Exercise Edit Row

struct ExerciseEditRow: View {
    @Bindable var exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: exercise.category.icon)
                    .foregroundStyle(Color(exercise.category.color))

                Text(exercise.name)
                    .font(.headline)

                Spacer()
            }

            HStack(spacing: 16) {
                // セット
                Stepper(value: $exercise.sets, in: 1...10) {
                    Text("\(exercise.sets)セット")
                        .font(.caption)
                }

                // レップ
                if !exercise.isTimeBasedExercise {
                    Stepper(value: $exercise.reps, in: 1...30) {
                        Text("\(exercise.reps)レップ")
                            .font(.caption)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Exercise Library View

struct ExerciseLibraryView: View {
    @Binding var selectedExercises: [Exercise]
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: ExerciseCategory?
    @State private var searchText = ""

    private var filteredExercises: [PresetExercise] {
        var exercises = PresetExercises.all

        if let category = selectedCategory {
            exercises = PresetExercises.exercises(for: category)
        }

        if !searchText.isEmpty {
            exercises = exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return exercises
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // カテゴリフィルター
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "すべて", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }

                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            FilterChip(
                                title: category.rawValue,
                                icon: category.icon,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // エクササイズ一覧
                List {
                    ForEach(filteredExercises) { preset in
                        Button {
                            addExercise(preset)
                        } label: {
                            HStack {
                                Image(systemName: preset.category.icon)
                                    .foregroundStyle(Color(preset.category.color))
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(preset.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    Text("\(preset.defaultSets)セット × \(preset.defaultReps)レップ")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "plus.circle")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("エクササイズを追加")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "検索")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addExercise(_ preset: PresetExercise) {
        let exercise = preset.toExercise()
        exercise.order = selectedExercises.count
        selectedExercises.append(exercise)
    }
}

// MARK: - Preview

#Preview {
    CreatePlanView(viewModel: FitnessCoachViewModel())
}
