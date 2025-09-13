//
//  PlanListView.swift
//  AsaWorkoutPlanner
//
//  ワークアウトプラン一覧画面
//

import SwiftUI
import AsaUIKit

struct PlanListView: View {
    // MARK: - Properties
    
    @Bindable var viewModel: WorkoutPlannerViewModel
    @State private var showingCreatePlan = false
    @State private var selectedPlanForDetail: WorkoutPlan?
    @State private var showingFilters = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.workoutPlans.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    planListContent
                }
            }
            .navigationTitle("ワークアウトプラン")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingFilters.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(Color(AsaColors.coffeeBrown))
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreatePlan = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(AsaColors.coffeeBrown))
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "プランを検索")
            .sheet(isPresented: $showingCreatePlan) {
                CreatePlanSheet(viewModel: viewModel)
            }
            .sheet(item: $selectedPlanForDetail) { plan in
                PlanDetailView(plan: plan, viewModel: viewModel)
            }
            .sheet(isPresented: $showingFilters) {
                FilterSheet(viewModel: viewModel)
            }
            .refreshable {
                viewModel.loadWorkoutPlans()
            }
        }
    }
    
    // MARK: - Components
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("プランがありません", systemImage: "list.bullet.rectangle")
        } description: {
            Text("最初のワークアウトプランを作成しましょう")
        } actions: {
            AsaButton(
                title: "プランを作成",
                action: {
                    showingCreatePlan = true
                },
                color: AsaColors.coffeeBrown
            )
            
            AsaButton(
                title: "サンプルプランを追加",
                action: {
                    viewModel.createSamplePlans()
                },
                color: AsaColors.softCream
            )
        }
    }
    
    private var planListContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.activeWorkoutPlan != nil {
                    activePlanSection
                }
                
                ForEach(viewModel.filteredPlans) { plan in
                    PlanCard(
                        plan: plan,
                        viewModel: viewModel,
                        onTap: {
                            selectedPlanForDetail = plan
                        }
                    )
                    .contextMenu {
                        planContextMenu(for: plan)
                    }
                }
            }
            .padding()
        }
    }
    
    private var activePlanSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("アクティブプラン")
                .font(.headline)
                .foregroundColor(Color(AsaColors.mutedSage))
            
            if let activePlan = viewModel.activeWorkoutPlan {
                ActivePlanCard(plan: activePlan, viewModel: viewModel)
            }
        }
    }
    
    @ViewBuilder
    private func planContextMenu(for plan: WorkoutPlan) -> some View {
        Button {
            viewModel.setActivePlan(plan)
        } label: {
            Label("アクティブに設定", systemImage: "star.fill")
        }
        
        Button {
            viewModel.duplicatePlan(plan)
        } label: {
            Label("複製", systemImage: "doc.on.doc")
        }
        
        Button {
            selectedPlanForDetail = plan
        } label: {
            Label("詳細を表示", systemImage: "info.circle")
        }
        
        Divider()
        
        Button(role: .destructive) {
            viewModel.deletePlan(plan)
        } label: {
            Label("削除", systemImage: "trash")
        }
    }
}

// MARK: - Supporting Views

struct PlanCard: View {
    let plan: WorkoutPlan
    @Bindable var viewModel: WorkoutPlannerViewModel
    let onTap: () -> Void
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: plan.category.icon)
                        .foregroundColor(Color(AsaColors.coffeeBrown))
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.headline)
                        
                        Text(plan.planDescription)
                            .font(.caption)
                            .foregroundColor(Color(AsaColors.mutedSage))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    if plan.isActive {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
                
                HStack {
                    DifficultyBadge(difficulty: plan.difficulty)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Label("\(plan.totalExercises)", systemImage: "figure.strengthtraining.traditional")
                        Label("\(Int(plan.estimatedDuration))分", systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundColor(Color(AsaColors.mutedSage))
                }
                
                if !plan.scheduledDays.isEmpty {
                    WeekDayIndicator(scheduledDays: plan.scheduledDays)
                }
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
        }
    }
}

struct ActivePlanCard: View {
    let plan: WorkoutPlan
    @Bindable var viewModel: WorkoutPlannerViewModel
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("完了セッション: \(plan.completedSessions)")
                            .font(.caption)
                            .foregroundColor(Color(AsaColors.mutedSage))
                    }
                    
                    Spacer()
                    
                    AsaButton(
                        title: "開始",
                        action: {
                            viewModel.startWorkoutSession(with: plan)
                        },
                        color: AsaColors.coffeeBrown
                    )
                }
                
                if let lastSession = plan.lastSessionDate {
                    Text("最終実施: \(lastSession.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(Color(AsaColors.mutedSage))
                }
            }
            .padding()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(AsaColors.coffeeBrown), lineWidth: 2)
        )
    }
}

struct DifficultyBadge: View {
    let difficulty: Difficulty
    
    var body: some View {
        Text(difficulty.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(difficulty.color).opacity(0.2))
            )
            .foregroundColor(Color(difficulty.color))
    }
}

struct WeekDayIndicator: View {
    let scheduledDays: [WeekDay]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(WeekDay.allCases, id: \.self) { day in
                Text(day.shortName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .frame(width: 20, height: 20)
                    .background(
                        Circle()
                            .fill(scheduledDays.contains(day) ? 
                                  Color(AsaColors.coffeeBrown) : 
                                  Color(AsaColors.mutedSage).opacity(0.2))
                    )
                    .foregroundColor(scheduledDays.contains(day) ? .white : Color(AsaColors.mutedSage))
            }
        }
    }
}

struct FilterSheet: View {
    @Bindable var viewModel: WorkoutPlannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("カテゴリー") {
                    Picker("カテゴリー", selection: $viewModel.selectedCategory) {
                        Text("すべて").tag(WorkoutCategory?.none)
                        ForEach(WorkoutCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category as WorkoutCategory?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("難易度") {
                    Picker("難易度", selection: $viewModel.selectedDifficulty) {
                        Text("すべて").tag(Difficulty?.none)
                        ForEach(Difficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.rawValue).tag(difficulty as Difficulty?)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    AsaButton(
                        title: "フィルターをリセット",
                        action: {
                            viewModel.selectedCategory = nil
                            viewModel.selectedDifficulty = nil
                            viewModel.searchText = ""
                        },
                        color: AsaColors.softCream
                    )
                }
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CreatePlanSheet: View {
    @Bindable var viewModel: WorkoutPlannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var planName = ""
    @State private var planDescription = ""
    @State private var selectedDifficulty: Difficulty = .intermediate
    @State private var selectedCategory: WorkoutCategory = .general
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("プラン名", text: $planName)
                    
                    TextField("説明", text: $planDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("設定") {
                    Picker("カテゴリー", selection: $selectedCategory) {
                        ForEach(WorkoutCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    
                    Picker("難易度", selection: $selectedDifficulty) {
                        ForEach(Difficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.rawValue).tag(difficulty)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    AsaButton(
                        title: "プランを作成",
                        action: {
                            createPlan()
                        },
                        color: AsaColors.coffeeBrown
                    )
                    .disabled(planName.isEmpty)
                }
            }
            .navigationTitle("新規プラン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createPlan() {
        viewModel.createWorkoutPlan(
            name: planName,
            description: planDescription,
            difficulty: selectedDifficulty,
            category: selectedCategory
        )
        dismiss()
    }
}