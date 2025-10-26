//
//  PlanDetailView.swift
//  AsaWorkoutPlanner
//
//  プラン詳細画面
//

import SwiftUI
import AsaUIKit

struct PlanDetailView: View {
    // MARK: - Properties
    
    let plan: WorkoutPlan
    @Bindable var viewModel: WorkoutPlannerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditExercise = false
    @State private var showingExerciseLibrary = false
    @State private var showingCreateExercise = false
    @State private var showingExerciseOptions = false
    @State private var showingScheduleEditor = false
    @State private var selectedExercise: Exercise?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // プラン情報
                    planInfoSection
                    
                    // スケジュール
                    if !plan.scheduledDays.isEmpty {
                        scheduleSection
                    }

                    // プログレッシブ・オーバーロード提案
                    progressiveOverloadSection

                    // エクササイズリスト
                    exerciseListSection
                    
                    // アクションボタン
                    actionButtons
                }
                .padding()
            }
            .navigationTitle(plan.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingExerciseLibrary) {
                ExerciseLibraryView(plan: plan, viewModel: viewModel)
            }
            .sheet(isPresented: $showingCreateExercise) {
                ExerciseEditorView(plan: plan, viewModel: viewModel)
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseEditorView(plan: plan, exerciseToEdit: exercise, viewModel: viewModel)
            }
            .sheet(isPresented: $showingScheduleEditor) {
                PlanScheduleEditorView(plan: plan)
            }
            .confirmationDialog("エクササイズを追加", isPresented: $showingExerciseOptions) {
                Button("ライブラリから選択") {
                    showingExerciseLibrary = true
                }
                Button("新規作成") {
                    showingCreateExercise = true
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }
    
    // MARK: - Components
    
    private var planInfoSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                if !plan.planDescription.isEmpty {
                    Text(plan.planDescription)
                        .font(.subheadline)
                        .foregroundColor(Color(AsaColors.darkSlate))
                }
                
                HStack {
                    Label(plan.category.rawValue, systemImage: plan.category.icon)
                        .font(.caption)
                    
                    Spacer()
                    
                    DifficultyBadge(difficulty: plan.difficulty)
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("総エクササイズ")
                            .font(.caption)
                            .foregroundColor(Color(AsaColors.mutedSage))
                        Text("\(plan.totalExercises)種目")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("推定時間")
                            .font(.caption)
                            .foregroundColor(Color(AsaColors.mutedSage))
                        Text("\(Int(plan.estimatedDuration))分")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("総セット数")
                            .font(.caption)
                            .foregroundColor(Color(AsaColors.mutedSage))
                        Text("\(plan.totalSets)セット")
                            .font(.headline)
                    }
                }
            }
            .padding()
        }
    }
    
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("スケジュール")
                    .font(.headline)

                Spacer()

                Button {
                    showingScheduleEditor = true
                } label: {
                    Label("編集", systemImage: "calendar.badge.clock")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(Color(AsaColors.coffeeBrown))
            }

            HStack(spacing: 8) {
                ForEach(WeekDay.allCases, id: \.self) { day in
                    VStack(spacing: 4) {
                        Text(day.shortName)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Circle()
                            .fill(plan.scheduledDays.contains(day) ?
                                  Color(AsaColors.coffeeBrown) :
                                  Color(AsaColors.mutedSage).opacity(0.2))
                            .frame(width: 10, height: 10)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(AsaColors.softCream).opacity(0.3))
            )
        }
    }

    private var progressiveOverloadSection: some View {
        let suggestions = viewModel.getProgressiveOverloadSuggestions(for: plan)

        return Group {
            if !suggestions.isEmpty {
                ProgressiveOverloadSuggestionView(suggestions: suggestions) { suggestion in
                    viewModel.applyProgressiveOverloadSuggestion(suggestion, to: plan)
                }
            }
        }
    }

    private var exerciseListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("エクササイズ")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showingExerciseOptions = true
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundColor(Color(AsaColors.coffeeBrown))
                }
            }
            
            if plan.exercises.isEmpty {
                AsaCard {
                    VStack(spacing: 12) {
                        Image(systemName: "figure.arms.open")
                            .font(.largeTitle)
                            .foregroundColor(Color(AsaColors.mutedSage))
                        
                        Text("エクササイズがありません")
                            .font(.subheadline)
                            .foregroundColor(Color(AsaColors.mutedSage))
                        
                        AsaButton(
                            title: "エクササイズを追加",
                            action: {
                                showingExerciseOptions = true
                            },
                            color: AsaColors.softCream
                        )
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(plan.exercises.sorted(by: { $0.order < $1.order })) { exercise in
                    ExerciseCard(exercise: exercise)
                        .onTapGesture {
                            selectedExercise = exercise
                        }
                        .contextMenu {
                            Button {
                                selectedExercise = exercise
                            } label: {
                                Label("編集", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                plan.removeExercise(exercise)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                }
                .onMove { from, to in
                    var exercises = plan.exercises.sorted(by: { $0.order < $1.order })
                    exercises.move(fromOffsets: from, toOffset: to)

                    // 順序を更新
                    for (index, exercise) in exercises.enumerated() {
                        exercise.order = index
                    }
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            AsaButton(
                title: "ワークアウトを開始",
                action: {
                    viewModel.startWorkoutSession(with: plan)
                    dismiss()
                },
                color: AsaColors.coffeeBrown
            )
            
            HStack(spacing: 12) {
                AsaButton(
                    title: "アクティブに設定",
                    action: {
                        viewModel.setActivePlan(plan)
                    },
                    color: AsaColors.softCream
                )
                .disabled(plan.isActive)
                
                AsaButton(
                    title: "複製",
                    action: {
                        viewModel.duplicatePlan(plan)
                        dismiss()
                    },
                    color: AsaColors.mocha
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct ExerciseCard: View {
    let exercise: Exercise
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Image(systemName: exercise.category.icon)
                                .foregroundColor(Color(exercise.category.color))
                            
                            Text(exercise.category.rawValue)
                                .font(.caption)
                                .foregroundColor(Color(AsaColors.mutedSage))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(AsaColors.mutedSage))
                }
                
                HStack(spacing: 20) {
                    // セット数
                    VStack(alignment: .leading, spacing: 2) {
                        Text("セット")
                            .font(.caption2)
                            .foregroundColor(Color(AsaColors.mutedSage))
                        Text("\(exercise.sets)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    // レップ数または時間
                    if exercise.isTimeBasedExercise {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("時間")
                                .font(.caption2)
                                .foregroundColor(Color(AsaColors.mutedSage))
                            Text(exercise.displayDuration)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("レップ")
                                .font(.caption2)
                                .foregroundColor(Color(AsaColors.mutedSage))
                            Text("\(exercise.reps)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // 重量
                    if let weight = exercise.weight {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("重量")
                                .font(.caption2)
                                .foregroundColor(Color(AsaColors.mutedSage))
                            Text("\(Int(weight))kg")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // 休憩時間
                    VStack(alignment: .leading, spacing: 2) {
                        Text("休憩")
                            .font(.caption2)
                            .foregroundColor(Color(AsaColors.mutedSage))
                        Text(exercise.displayRestTime)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
                
                if let notes = exercise.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(Color(AsaColors.mutedSage))
                        .lineLimit(2)
                }
            }
            .padding()
        }
    }
}