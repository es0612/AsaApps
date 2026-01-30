//
//  PlanDetailView.swift
//  AsaFitnessCoach
//
//  プラン詳細画面
//

import SwiftUI

struct PlanDetailView: View {
    // MARK: - Properties

    @Bindable var viewModel: FitnessCoachViewModel
    @Bindable var plan: WorkoutPlan
    @Environment(\.dismiss) private var dismiss

    @State private var showEditPlan = false
    @State private var showStartWorkout = false
    @State private var showDeleteConfirmation = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ヘッダー
                headerSection

                // 基本情報
                infoSection

                // スケジュール
                if !plan.scheduledDays.isEmpty {
                    scheduleSection
                }

                // エクササイズ一覧
                exercisesSection

                // 実績
                if !plan.sessions.isEmpty {
                    historySection
                }

                // アクションボタン
                actionButtons
            }
            .padding()
        }
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showEditPlan = true
                    } label: {
                        Label("編集", systemImage: "pencil")
                    }

                    Button {
                        viewModel.togglePlanActive(plan)
                    } label: {
                        Label(
                            plan.isActive ? "非アクティブにする" : "アクティブにする",
                            systemImage: plan.isActive ? "xmark.circle" : "checkmark.circle"
                        )
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditPlan) {
            CreatePlanView(viewModel: viewModel, editingPlan: plan)
        }
        .sheet(isPresented: $showStartWorkout) {
            WorkoutSessionView(viewModel: viewModel, plan: plan)
        }
        .confirmationDialog(
            "このプランを削除しますか？",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                viewModel.deletePlan(plan)
                dismiss()
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 12) {
            // カテゴリアイコン
            Image(systemName: plan.category.icon)
                .font(.system(size: 50))
                .foregroundStyle(Color(plan.category.color))
                .frame(width: 100, height: 100)
                .background(Color(plan.category.color).opacity(0.1))
                .clipShape(Circle())

            // タイトル
            HStack {
                Text(plan.name)
                    .font(.title2)
                    .fontWeight(.bold)

                if plan.isAIGenerated {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                }
            }

            // 説明
            if !plan.planDescription.isEmpty {
                Text(plan.planDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // AI信頼度
            if let confidence = plan.aiConfidence {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption)
                    Text("AI信頼度: \(Int(confidence * 100))%")
                        .font(.caption)
                }
                .foregroundStyle(.purple)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }

    private var infoSection: some View {
        HStack(spacing: 0) {
            InfoItem(
                icon: "clock",
                value: plan.displayEstimatedDuration,
                label: "時間"
            )

            Divider()
                .frame(height: 40)

            InfoItem(
                icon: "figure.strengthtraining.traditional",
                value: "\(plan.totalExercises)",
                label: "種目"
            )

            Divider()
                .frame(height: 40)

            InfoItem(
                icon: "number",
                value: "\(plan.totalSets)",
                label: "セット"
            )

            Divider()
                .frame(height: 40)

            InfoItem(
                icon: "chart.bar",
                value: plan.difficulty.rawValue,
                label: "難易度"
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("スケジュール")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(WeekDay.allCases, id: \.self) { day in
                    let isScheduled = plan.scheduledDays.contains(day)
                    Text(day.shortName)
                        .font(.caption)
                        .fontWeight(isScheduled ? .bold : .regular)
                        .foregroundStyle(isScheduled ? .white : .secondary)
                        .frame(width: 36, height: 36)
                        .background(isScheduled ? Color.accentColor : Color(.secondarySystemBackground))
                        .clipShape(Circle())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("エクササイズ")
                .font(.headline)

            ForEach(plan.exercises.sorted { $0.order < $1.order }) { exercise in
                ExerciseRow(exercise: exercise)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("実績")
                .font(.headline)

            HStack(spacing: 20) {
                VStack {
                    Text("\(plan.completedSessions)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("完了回数")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let lastDate = plan.lastSessionDate {
                    VStack {
                        Text(lastDate, style: .date)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("最終実行")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack {
                    Text("\(Int(plan.completionRate))%")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("完了率")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var actionButtons: some View {
        Button {
            showStartWorkout = true
        } label: {
            Label("ワークアウトを開始", systemImage: "play.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Supporting Views

struct InfoItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            Text("\(exercise.order + 1)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.accentColor)
                .clipShape(Circle())

            Image(systemName: exercise.category.icon)
                .font(.body)
                .foregroundStyle(Color(exercise.category.color))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    if exercise.isTimeBasedExercise {
                        Text("\(exercise.sets)セット × \(exercise.displayDuration)")
                    } else {
                        Text("\(exercise.sets)セット × \(exercise.reps)レップ")
                    }

                    if let weight = exercise.weight {
                        Text("@ \(Int(weight))kg")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(exercise.displayRestTime)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        let plan = WorkoutPlan(
            name: "筋力アッププラン",
            description: "上半身を中心とした筋力トレーニング",
            difficulty: .intermediate,
            category: .strength
        )
        plan.isAIGenerated = true
        plan.aiConfidence = 0.85
        plan.scheduledDays = [.monday, .wednesday, .friday]
        plan.estimatedDuration = 45

        return PlanDetailView(viewModel: FitnessCoachViewModel(), plan: plan)
    }
}
