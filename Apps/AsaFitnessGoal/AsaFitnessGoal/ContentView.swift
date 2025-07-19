//
//  ContentView.swift
//  AsaFitnessGoal
//  
//  Created on 2025/07/19
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = FitnessViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "chart.pie")
                    Text("ダッシュボード")
                }
                .tag(0)
            
            GoalsListView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "target")
                    Text("目標")
                }
                .tag(1)
            
            RecordsListView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("記録")
                }
                .tag(2)
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
}

// MARK: - ダッシュボードビュー
struct DashboardView: View {
    let viewModel: FitnessViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // 今日の進捗サマリー
                    AsaCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("今日の進捗")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("AsaDarkSlate"))
                            
                            if viewModel.isLoadingProgress {
                                ProgressView("データを読み込み中...")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else if viewModel.activeGoals.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "target")
                                        .font(.system(size: 40))
                                        .foregroundColor(Color("AsaMutedSage"))
                                    
                                    Text("目標を設定して運動を始めましょう！")
                                        .font(.body)
                                        .foregroundColor(Color("AsaMocha"))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            } else {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    ForEach(viewModel.activeGoals, id: \.id) { goal in
                                        GoalProgressCard(goal: goal, viewModel: viewModel)
                                    }
                                }
                            }
                        }
                    }
                    
                    // 今週の達成状況
                    if !viewModel.completedGoals.isEmpty {
                        AsaCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("今週の達成")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("AsaDarkSlate"))
                                
                                ForEach(viewModel.completedGoals, id: \.id) { goal in
                                    HStack {
                                        Image(systemName: goal.category.icon)
                                            .foregroundColor(Color("AsaCoffeeBrown"))
                                        
                                        Text(goal.title)
                                            .font(.body)
                                            .foregroundColor(Color("AsaDarkSlate"))
                                        
                                        Spacer()
                                        
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    
                    // 最近の記録
                    if !viewModel.getRecentRecords().isEmpty {
                        AsaCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("最近の記録")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("AsaDarkSlate"))
                                
                                ForEach(viewModel.getRecentRecords(limit: 5), id: \.id) { record in
                                    RecentRecordRow(record: record)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("フィットネス目標")
            .refreshable {
                await viewModel.loadCurrentProgress()
            }
            .task {
                await viewModel.loadCurrentProgress()
            }
        }
    }
}

// MARK: - 目標進捗カード
struct GoalProgressCard: View {
    let goal: FitnessGoal
    let viewModel: FitnessViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            // アイコンと進捗円グラフ
            ZStack {
                Circle()
                    .stroke(Color("AsaSoftCream"), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: viewModel.getProgress(for: goal))
                    .stroke(Color("AsaCoffeeBrown"), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: viewModel.getProgress(for: goal))
                
                Image(systemName: goal.category.icon)
                    .font(.title2)
                    .foregroundColor(Color("AsaDarkSlate"))
            }
            
            // 目標情報
            Text(goal.category.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaMocha"))
            
            Text(viewModel.getProgressText(for: goal))
                .font(.caption2)
                .foregroundColor(Color("AsaMutedSage"))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 最近の記録行
struct RecentRecordRow: View {
    let record: WorkoutRecord
    
    var body: some View {
        HStack {
            Image(systemName: record.category.icon)
                .foregroundColor(Color("AsaCoffeeBrown"))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(record.category.displayName)
                    .font(.body)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text(record.recordedAt, style: .time)
                    .font(.caption)
                    .foregroundColor(Color("AsaMutedSage"))
            }
            
            Spacer()
            
            Text("\(record.formattedValue) \(record.category.unit)")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaMocha"))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 目標一覧ビュー
struct GoalsListView: View {
    let viewModel: FitnessViewModel
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.goals.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "target")
                            .font(.system(size: 50))
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Text("目標がありません")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        Text("新しい目標を作成して\n運動習慣を始めましょう！")
                            .font(.body)
                            .foregroundColor(Color("AsaMocha"))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(viewModel.goals, id: \.id) { goal in
                        GoalListRow(goal: goal, viewModel: viewModel)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteGoals)
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("目標管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.showAddGoalSheet) {
                        Image(systemName: "plus")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel.isShowingAddGoalSheet },
                set: { _ in viewModel.hideAddGoalSheet() }
            )) {
                AddGoalView(viewModel: viewModel)
            }
            .sheet(isPresented: Binding(
                get: { viewModel.isShowingEditGoalSheet },
                set: { _ in viewModel.hideEditGoalSheet() }
            )) {
                if let selectedGoal = viewModel.selectedGoal {
                    EditGoalView(goal: selectedGoal, viewModel: viewModel)
                }
            }
        }
    }
    
    private func deleteGoals(offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteGoal(viewModel.goals[index])
        }
    }
}

// MARK: - 目標リスト行
struct GoalListRow: View {
    let goal: FitnessGoal
    let viewModel: FitnessViewModel
    
    var body: some View {
        AsaCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: goal.category.icon)
                        .font(.title2)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.title)
                            .font(.headline)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        Text("\(goal.category.displayName) • \(goal.period.displayName)")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(viewModel.getProgressText(for: goal))
                            .font(.caption)
                            .foregroundColor(Color("AsaMocha"))
                        
                        if !goal.isActive {
                            Text("非アクティブ")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                // 進捗バー
                ProgressView(value: viewModel.getProgress(for: goal))
                    .progressViewStyle(LinearProgressViewStyle(tint: Color("AsaCoffeeBrown")))
                    .background(Color("AsaSoftCream"))
                    .cornerRadius(4)
                
                // アクションボタン
                HStack(spacing: 12) {
                    Button(action: { viewModel.showEditGoalSheet(for: goal) }) {
                        Text("編集")
                            .font(.caption)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    
                    Button(action: { viewModel.toggleGoalActive(goal) }) {
                        Text(goal.isActive ? "無効化" : "有効化")
                            .font(.caption)
                            .foregroundColor(goal.isActive ? .orange : .green)
                    }
                    
                    Spacer()
                    
                    if viewModel.getProgress(for: goal) >= 1.0 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
}

// MARK: - 記録一覧ビュー
struct RecordsListView: View {
    let viewModel: FitnessViewModel
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.workoutRecords.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 50))
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Text("記録がありません")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        Text("運動記録を追加して\n進捗を追跡しましょう！")
                            .font(.body)
                            .foregroundColor(Color("AsaMocha"))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(viewModel.workoutRecords, id: \.id) { record in
                        WorkoutRecordRow(record: record)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteRecords)
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("運動記録")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.showAddRecordSheet) {
                        Image(systemName: "plus")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel.isShowingAddRecordSheet },
                set: { _ in viewModel.hideAddRecordSheet() }
            )) {
                AddRecordView(viewModel: viewModel)
            }
        }
    }
    
    private func deleteRecords(offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteWorkoutRecord(viewModel.workoutRecords[index])
        }
    }
}

// MARK: - ワークアウト記録行
struct WorkoutRecordRow: View {
    let record: WorkoutRecord
    
    var body: some View {
        AsaCard {
            HStack {
                Image(systemName: record.category.icon)
                    .font(.title2)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.category.displayName)
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    Text(record.recordedAt, format: .dateTime.month().day().hour().minute())
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                    
                    if !record.note.isEmpty {
                        Text(record.note)
                            .font(.caption)
                            .foregroundColor(Color("AsaMocha"))
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(record.formattedValue) \(record.category.unit)")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    if record.isManualEntry {
                        Text("手動入力")
                            .font(.caption2)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FitnessGoal.self, inMemory: true)
}
