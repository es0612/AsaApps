//
//  TaskListView.swift
//  AsaVoiceAssistant
//
//  タスク一覧画面
//

import SwiftUI
import AsaUIKit

/// タスク一覧画面
///
/// すべてのタスクをリスト表示し、フィルタリングと検索機能を提供します。
struct TaskListView: View {
    // MARK: - Properties

    @Bindable var viewModel: VoiceAssistantViewModel
    @State private var taskListViewModel: TaskListViewModel
    @State private var showingAddTask = false
    @State private var selectedFilter: TaskFilter = .active

    // MARK: - Initialization

    init(viewModel: VoiceAssistantViewModel) {
        self.viewModel = viewModel
        self._taskListViewModel = State(initialValue: TaskListViewModel(dataService: DataService(inMemory: false)))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AsaColors.softCream
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // フィルターチップ
                    filterChips

                    // タスクリスト
                    if taskListViewModel.displayTasks.isEmpty {
                        emptyStateView
                    } else {
                        taskList
                    }
                }
            }
            .navigationTitle("タスク一覧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }
            }
            .searchable(text: $taskListViewModel.searchText, prompt: "タスクを検索")
            .sheet(isPresented: $showingAddTask) {
                AddTaskSheet(viewModel: viewModel) {
                    refreshTasks()
                }
            }
            .onAppear {
                refreshTasks()
            }
            .onChange(of: viewModel.tasks) { _, _ in
                refreshTasks()
            }
        }
    }

    // MARK: - Subviews

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "未完了",
                    count: taskListViewModel.activeTaskCount,
                    isSelected: selectedFilter == .active,
                    action: { selectFilter(.active) }
                )

                FilterChip(
                    title: "今日",
                    count: taskListViewModel.todayTaskCount,
                    isSelected: selectedFilter == .today,
                    action: { selectFilter(.today) }
                )

                FilterChip(
                    title: "期限切れ",
                    count: taskListViewModel.overdueTaskCount,
                    isSelected: selectedFilter == .overdue,
                    color: .red,
                    action: { selectFilter(.overdue) }
                )

                FilterChip(
                    title: "完了済み",
                    count: taskListViewModel.completedTaskCount,
                    isSelected: selectedFilter == .completed,
                    action: { selectFilter(.completed) }
                )

                FilterChip(
                    title: "すべて",
                    isSelected: selectedFilter == .all,
                    action: { selectFilter(.all) }
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(AsaColors.mutedSage.opacity(0.5))

            Text(emptyStateMessage)
                .font(.body)
                .foregroundColor(AsaColors.mutedSage)
                .multilineTextAlignment(.center)

            if selectedFilter == .active {
                Button(action: { showingAddTask = true }) {
                    Text("タスクを追加")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(AsaColors.coffeeBrown)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var emptyStateMessage: String {
        switch selectedFilter {
        case .active:
            return "未完了のタスクはありません\n声またはボタンでタスクを追加しましょう"
        case .completed:
            return "完了済みのタスクはありません"
        case .today:
            return "今日期限のタスクはありません"
        case .overdue:
            return "期限切れのタスクはありません"
        default:
            return "タスクが見つかりませんでした"
        }
    }

    private var taskList: some View {
        List {
            ForEach(taskListViewModel.displayTasks, id: \.id) { task in
                TaskRowView(
                    task: task,
                    onToggleCompletion: {
                        viewModel.toggleTaskCompletion(task)
                    },
                    onDelete: {
                        viewModel.deleteTask(task)
                    }
                )
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .background(AsaColors.softCream)
    }

    // MARK: - Actions

    private func selectFilter(_ filter: TaskFilter) {
        selectedFilter = filter
        taskListViewModel.currentFilter = filter
    }

    private func refreshTasks() {
        taskListViewModel.setTasks(viewModel.tasks)
    }
}

/// フィルターチップ
struct FilterChip: View {
    let title: String
    var count: Int? = nil
    let isSelected: Bool
    var color: Color = AsaColors.coffeeBrown
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? color.opacity(0.3) : color.opacity(0.1))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : AsaColors.darkSlate)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

/// タスク追加シート
struct AddTaskSheet: View {
    @Bindable var viewModel: VoiceAssistantViewModel
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var priority: PriorityLevel = .medium
    @State private var category: TaskCategory = .other
    @State private var hasDueDate = false
    @State private var dueDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("タスク情報") {
                    TextField("タイトル", text: $title)

                    TextField("説明（オプション）", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                }

                Section("カテゴリと優先度") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(TaskCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }

                    Picker("優先度", selection: $priority) {
                        ForEach(PriorityLevel.allCases) { level in
                            Text(level.displayName)
                                .tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("期限") {
                    Toggle("期限を設定", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("期限日", selection: $dueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("タスクを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func addTask() {
        viewModel.addTask(
            title: title,
            description: description.isEmpty ? nil : description,
            priority: priority,
            category: category,
            dueDate: hasDueDate ? dueDate : nil
        )
        onComplete()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let dataService = DataService(inMemory: true)
    let viewModel = VoiceAssistantViewModel(dataService: dataService)

    return TaskListView(viewModel: viewModel)
}
