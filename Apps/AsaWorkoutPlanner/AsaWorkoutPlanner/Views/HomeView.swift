//
//  HomeView.swift
//  AsaWorkoutPlanner
//
//  ホーム画面 - ダッシュボード
//

import SwiftUI
import AsaUIKit
import Charts

struct HomeView: View {
    // MARK: - Properties
    
    @Bindable var viewModel: WorkoutPlannerViewModel
    @State private var showingQuickStart = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダー
                    headerSection
                    
                    // 今日のワークアウト
                    if let todaysWorkout = viewModel.todaysWorkout {
                        todaysWorkoutCard(todaysWorkout)
                    } else {
                        noWorkoutCard
                    }
                    
                    // 週間進捗
                    weeklyProgressCard
                    
                    // 統計サマリー
                    statisticsGrid
                    
                    // 最近のセッション
                    if !viewModel.recentSessions.isEmpty {
                        recentSessionsSection
                    }
                }
                .padding()
            }
            .navigationTitle("AsaWorkoutPlanner")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingQuickStart = true
                    } label: {
                        Image(systemName: "bolt.circle.fill")
                            .foregroundColor(Color(AsaColors.coffeeBrown))
                    }
                }
            }
            .sheet(isPresented: $showingQuickStart) {
                QuickStartSheet(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingText)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(motivationalQuote)
                .font(.subheadline)
                .foregroundColor(Color(AsaColors.mutedSage))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func todaysWorkoutCard(_ plan: WorkoutPlan) -> some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar.day.timeline.left")
                        .foregroundColor(Color(AsaColors.coffeeBrown))
                    Text("今日のワークアウト")
                        .font(.headline)
                    Spacer()
                }
                
                Text(plan.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                HStack {
                    Label("\(plan.totalExercises)種目", systemImage: "figure.strengthtraining.traditional")
                    Spacer()
                    Label("\(Int(plan.estimatedDuration))分", systemImage: "clock")
                }
                .font(.caption)
                .foregroundColor(Color(AsaColors.mutedSage))
                
                AsaButton(
                    title: "開始",
                    action: {
                        viewModel.startWorkoutSession(with: plan)
                    },
                    color: AsaColors.coffeeBrown
                )
            }
            .padding()
        }
    }
    
    private var noWorkoutCard: some View {
        AsaCard {
            VStack(spacing: 12) {
                Image(systemName: "calendar.badge.plus")
                    .font(.largeTitle)
                    .foregroundColor(Color(AsaColors.mutedSage))
                
                Text("今日はワークアウトの予定がありません")
                    .font(.subheadline)
                    .foregroundColor(Color(AsaColors.mutedSage))
                
                AsaButton(
                    title: "プランを選択",
                    action: {
                        // プラン選択画面へ
                    },
                    color: AsaColors.softCream
                )
            }
            .padding()
        }
    }
    
    private var weeklyProgressCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(Color(AsaColors.coffeeBrown))
                    Text("週間進捗")
                        .font(.headline)
                    Spacer()
                    Text("\(viewModel.weeklyProgress)/\(viewModel.weeklyGoal)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                SwiftUI.ProgressView(value: viewModel.weeklyProgressPercentage)
                    .tint(Color(AsaColors.coffeeBrown))
                    .scaleEffect(x: 1, y: 2)
                
                if viewModel.weeklyProgress >= viewModel.weeklyGoal {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("目標達成！素晴らしい！")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
        }
    }
    
    private var statisticsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "総ワークアウト",
                value: "\(viewModel.totalWorkouts)",
                icon: "figure.run",
                color: AsaColors.coffeeBrown
            )
            
            StatCard(
                title: "合計時間",
                value: formatDuration(viewModel.totalDuration),
                icon: "clock.fill",
                color: AsaColors.mocha
            )
            
            StatCard(
                title: "消費カロリー",
                value: "\(Int(viewModel.totalCaloriesBurned))",
                unit: "kcal",
                icon: "flame.fill",
                color: AsaColors.softCream
            )
            
            StatCard(
                title: "連続日数",
                value: "\(viewModel.currentStreak)",
                unit: "日",
                icon: "flame",
                color: AsaColors.mutedSage
            )
        }
    }
    
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近のセッション")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(viewModel.recentSessions.prefix(3)) { session in
                SessionRow(session: session)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "おはようございます！"
        case 12..<17:
            return "こんにちは！"
        case 17..<22:
            return "こんばんは！"
        default:
            return "お疲れ様です！"
        }
    }
    
    private var motivationalQuote: String {
        let quotes = [
            "今日も一歩前進しましょう",
            "継続は力なり",
            "小さな努力が大きな成果を生む",
            "あなたの限界はあなたが決める",
            "今日の運動は明日の健康"
        ]
        return quotes.randomElement() ?? quotes[0]
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)分"
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    var unit: String = ""
    let icon: String
    let color: Color
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Spacer()
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color(AsaColors.mutedSage))
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(Color(AsaColors.mutedSage))
                    }
                }
            }
            .padding()
        }
    }
}

struct SessionRow: View {
    let session: WorkoutSession
    
    var body: some View {
        AsaCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.workoutPlan?.name ?? "ワークアウト")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(session.sessionDate)
                        .font(.caption)
                        .foregroundColor(Color(AsaColors.mutedSage))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(session.completionPercentage)%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(completionColor)
                    
                    Text(session.displayDuration)
                        .font(.caption)
                        .foregroundColor(Color(AsaColors.mutedSage))
                }
            }
            .padding()
        }
    }
    
    private var completionColor: Color {
        if session.completionPercentage >= 100 {
            return .green
        } else if session.completionPercentage >= 70 {
            return .orange
        } else {
            return .red
        }
    }
}

struct QuickStartSheet: View {
    @Bindable var viewModel: WorkoutPlannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("クイックスタート")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("プランを選択してワークアウトを開始")
                    .font(.subheadline)
                    .foregroundColor(Color(AsaColors.mutedSage))
                
                if viewModel.workoutPlans.isEmpty {
                    ContentUnavailableView(
                        "プランがありません",
                        systemImage: "list.bullet.rectangle",
                        description: Text("最初のワークアウトプランを作成してください")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.workoutPlans) { plan in
                                Button {
                                    viewModel.startWorkoutSession(with: plan)
                                    dismiss()
                                } label: {
                                    PlanQuickCard(plan: plan)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .padding()
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
}

struct PlanQuickCard: View {
    let plan: WorkoutPlan
    
    var body: some View {
        AsaCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(.headline)
                    
                    HStack {
                        Label("\(plan.totalExercises)種目", systemImage: plan.category.icon)
                        Text("•")
                        Text("\(Int(plan.estimatedDuration))分")
                    }
                    .font(.caption)
                    .foregroundColor(Color(AsaColors.mutedSage))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(AsaColors.coffeeBrown))
            }
            .padding()
        }
    }
}