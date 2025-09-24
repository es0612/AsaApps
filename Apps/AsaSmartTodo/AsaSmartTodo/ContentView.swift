import SwiftUI
import SwiftData
import AsaUIKit

struct ContentView: View {
    @EnvironmentObject private var viewModel: SmartTodoViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // メインタスクリスト
            NavigationStack {
                TaskListView()
                    .navigationTitle("AsaSmartTodo")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        toolbarContent
                    }
            }
            .tabItem {
                Label("タスク", systemImage: "checklist")
            }
            .tag(0)

            // AI インサイト
            NavigationStack {
                AIInsightsView()
                    .navigationTitle("AI インサイト")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("AI分析", systemImage: "brain")
            }
            .tag(1)

            // 統計・レポート
            NavigationStack {
                AnalyticsView()
                    .navigationTitle("レポート")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("レポート", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(2)
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .sheet(isPresented: $viewModel.showingAddTask) {
            TaskInputView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $viewModel.showingTaskDetail) {
            if let task = viewModel.selectedTask {
                TaskDetailView(task: task)
                    .environmentObject(viewModel)
            }
        }
        .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                viewModel.showingAddTask = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(AsaColors.coffeeBrown)
                    .font(.title2)
            }
        }

        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    Button(filter.rawValue) {
                        viewModel.setFilter(filter)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text(viewModel.currentFilter.rawValue)
                        .font(.caption)
                }
                .foregroundColor(AsaColors.coffeeBrown)
            }
        }
    }
}

// MARK: - Task List View

struct TaskListView: View {
    @EnvironmentObject private var viewModel: SmartTodoViewModel

    var body: some View {
        ZStack {
            AsaColors.softCream.opacity(0.3)
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView("読み込み中...")
                    .progressViewStyle(CircularProgressViewStyle(tint: AsaColors.coffeeBrown))
            } else if viewModel.filteredTasks.isEmpty {
                emptyStateView
            } else {
                tasksList
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "タスクを検索")
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.applyFilter()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.badge.xmark")
                .font(.system(size: 60))
                .foregroundColor(AsaColors.mutedSage)

            Text("タスクがありません")
                .font(.title2)
                .foregroundColor(AsaColors.darkSlate)

            Text("＋ボタンから新しいタスクを追加してください")
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)
        }
        .padding()
    }

    private var tasksList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // 統計サマリー
                if viewModel.currentFilter == .all {
                    summaryCard
                }

                // タスクカード
                ForEach(viewModel.filteredTasks, id: \.id) { task in
                    SmartTaskCard(task: task)
                        .onTapGesture {
                            viewModel.selectedTask = task
                            viewModel.showingTaskDetail = true
                        }
                }
            }
            .padding()
        }
    }

    private var summaryCard: some View {
        AsaCard {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日の完了")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                    Text("\(viewModel.todayCompletedCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AsaColors.coffeeBrown)
                }

                Divider()
                    .frame(height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text("未完了")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                    Text("\(viewModel.pendingTasksCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AsaColors.darkSlate)
                }

                Divider()
                    .frame(height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI精度")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                    Text("\(Int(viewModel.aiAccuracyRate * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AsaColors.mocha)
                }

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Smart Task Card

struct SmartTaskCard: View {
    let task: SmartTask
    @EnvironmentObject private var viewModel: SmartTodoViewModel

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー
                HStack {
                    // 優先度インジケータ
                    Circle()
                        .fill(priorityColor(task.userPriority))
                        .frame(width: 12, height: 12)

                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                        .lineLimit(2)

                    Spacer()

                    // AI提案バッジ
                    if task.aiSuggestedPriority != task.userPriority && !task.feedbackProvided {
                        AIBadge(priority: task.aiSuggestedPriority, confidence: task.confidenceScore)
                    }
                }

                // 説明
                if let description = task.taskDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(AsaColors.darkSlate.opacity(0.7))
                        .lineLimit(2)
                }

                // フッター
                HStack {
                    // カテゴリタグ
                    Label(task.category.rawValue, systemImage: categoryIcon(task.category))
                        .font(.caption2)
                        .foregroundColor(AsaColors.mutedSage)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AsaColors.softCream)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Spacer()

                    // 期限表示
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: task.isOverdue ? "exclamationmark.circle.fill" : "calendar")
                                .font(.caption2)
                            Text(formatDate(dueDate))
                                .font(.caption2)
                        }
                        .foregroundColor(task.isOverdue ? .red : AsaColors.darkSlate.opacity(0.7))
                    }

                    // 完了ボタン
                    Button {
                        withAnimation {
                            viewModel.completeTask(task)
                        }
                    } label: {
                        Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.status == .done ? AsaColors.coffeeBrown : AsaColors.mutedSage)
                    }
                }
            }
            .padding()
        }
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high:
            return Color.red
        case .medium:
            return AsaColors.coffeeBrown
        case .low:
            return AsaColors.mutedSage
        }
    }

    private func categoryIcon(_ category: TaskCategory) -> String {
        switch category {
        case .work: return "briefcase"
        case .personal: return "person"
        case .family: return "house"
        case .health: return "heart"
        case .learning: return "book"
        case .other: return "folder"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")

        if Calendar.current.isDateInToday(date) {
            return "今日"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "明日"
        } else {
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - AI Badge

struct AIBadge: View {
    let priority: TaskPriority
    let confidence: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "brain")
                .font(.caption2)
            Text(priority.displayName)
                .font(.caption2)
                .fontWeight(.medium)
            Text("\(Int(confidence * 100))%")
                .font(.caption2)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            LinearGradient(
                colors: [AsaColors.mocha, AsaColors.coffeeBrown],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(SmartTodoViewModel())
        .modelContainer(for: [SmartTask.self, TaskAnalytics.self], inMemory: true)
}