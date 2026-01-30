//
//  PlanListView.swift
//  AsaFitnessCoach
//
//  プラン一覧画面
//

import SwiftUI

struct PlanListView: View {
    // MARK: - Properties

    @Bindable var viewModel: FitnessCoachViewModel
    @State private var showCreatePlan = false
    @State private var selectedCategory: WorkoutCategory?
    @State private var searchText = ""

    private var filteredPlans: [WorkoutPlan] {
        var plans = viewModel.workoutPlans

        if let category = selectedCategory {
            plans = plans.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            plans = plans.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return plans
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // カテゴリフィルター
                categoryFilter

                // プラン一覧
                if filteredPlans.isEmpty {
                    emptyState
                } else {
                    planList
                }
            }
            .navigationTitle("ワークアウトプラン")
            .searchable(text: $searchText, prompt: "プランを検索")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreatePlan = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreatePlan) {
                CreatePlanView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Views

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "すべて",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(WorkoutCategory.allCases, id: \.self) { category in
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
        .background(Color(.systemBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("プランがありません")
                .font(.headline)

            Text("新しいワークアウトプランを作成するか、\nAI提案を試してみましょう")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showCreatePlan = true
            } label: {
                Label("プランを作成", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxHeight: .infinity)
        .padding()
    }

    private var planList: some View {
        List {
            ForEach(filteredPlans) { plan in
                NavigationLink {
                    PlanDetailView(viewModel: viewModel, plan: plan)
                } label: {
                    PlanRow(plan: plan)
                }
            }
            .onDelete(perform: deletePlans)
        }
        .listStyle(.plain)
    }

    // MARK: - Methods

    private func deletePlans(at offsets: IndexSet) {
        for index in offsets {
            let plan = filteredPlans[index]
            viewModel.deletePlan(plan)
        }
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
            .clipShape(Capsule())
        }
    }
}

struct PlanRow: View {
    let plan: WorkoutPlan

    var body: some View {
        HStack(spacing: 12) {
            // カテゴリアイコン
            Image(systemName: plan.category.icon)
                .font(.title2)
                .foregroundStyle(Color(plan.category.color))
                .frame(width: 44, height: 44)
                .background(Color(plan.category.color).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(plan.name)
                        .font(.headline)

                    if plan.isAIGenerated {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }
                }

                HStack(spacing: 8) {
                    Label(plan.displayEstimatedDuration, systemImage: "clock")
                    Label("\(plan.totalExercises)種目", systemImage: "figure.strengthtraining.traditional")
                    Label(plan.difficulty.rawValue, systemImage: "chart.bar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if plan.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    PlanListView(viewModel: FitnessCoachViewModel())
}
