import SwiftUI
import AsaUIKit
import AsaTaskKit

struct TaskDetailView: View {
    let task: Task
    
    @EnvironmentObject private var viewModel: TaskBoardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    
    // 編集用のState
    @State private var editTitle: String
    @State private var editDescription: String
    @State private var editPriority: TaskPriority
    @State private var editDueDate: Date?
    @State private var hasEditDueDate: Bool
    
    init(task: Task) {
        self.task = task
        self._editTitle = State(initialValue: task.title)
        self._editDescription = State(initialValue: task.taskDescription ?? "")
        self._editPriority = State(initialValue: task.priority)
        self._editDueDate = State(initialValue: task.dueDate)
        self._hasEditDueDate = State(initialValue: task.dueDate != nil)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AsaColors.softCream.opacity(0.3)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // ステータスカード
                        statusCard
                        
                        // タスク詳細
                        if isEditing {
                            editingContent
                        } else {
                            viewingContent
                        }
                        
                        // アクションボタン
                        actionButtons
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("タスク詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    editButton
                }
            }
        }
    }
    
    // MARK: - Views
    
    private var statusCard: some View {
        AsaCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.status.displayName)
                        .font(.headline)
                        .foregroundColor(statusColor)
                    
                    Text("作成日: \(formattedDate(task.createdAt))")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
                
                Spacer()
                
                Image(systemName: task.status.systemImageName)
                    .font(.title2)
                    .foregroundColor(statusColor)
            }
        }
    }
    
    private var viewingContent: some View {
        VStack(spacing: 16) {
            // タイトル
            AsaCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("タスク名")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    
                    Text(task.title)
                        .font(.body)
                        .foregroundColor(AsaColors.darkSlate)
                }
            }
            
            // 説明
            if let description = task.taskDescription, !description.isEmpty {
                AsaCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("説明")
                            .font(.headline)
                            .foregroundColor(AsaColors.darkSlate)
                        
                        Text(description)
                            .font(.body)
                            .foregroundColor(AsaColors.darkSlate)
                    }
                }
            }
            
            // 優先度と期日
            detailsCard
        }
    }
    
    private var editingContent: some View {
        VStack(spacing: 16) {
            // タイトル編集
            AsaCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("タスク名")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    
                    TextField("タスク名", text: $editTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            // 説明編集
            AsaCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("説明")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    
                    TextField("説明", text: $editDescription, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
            }
            
            // 優先度編集
            AsaCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("優先度")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    
                    Picker("優先度", selection: $editPriority) {
                        ForEach(TaskPriority.allCases, id: \.id) { priority in
                            HStack {
                                Circle()
                                    .fill(priorityColor(priority))
                                    .frame(width: 12, height: 12)
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            // 期日編集
            AsaCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("期日")
                            .font(.headline)
                            .foregroundColor(AsaColors.darkSlate)
                        
                        Spacer()
                        
                        Toggle("", isOn: $hasEditDueDate)
                            .toggleStyle(SwitchToggleStyle(tint: AsaColors.coffeeBrown))
                    }
                    
                    if hasEditDueDate {
                        DatePicker(
                            "期日を選択",
                            selection: Binding(
                                get: { editDueDate ?? Date() },
                                set: { editDueDate = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                    }
                }
            }
        }
    }
    
    private var detailsCard: some View {
        AsaCard {
            VStack(spacing: 12) {
                // 優先度
                HStack {
                    Text("優先度")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(priorityColor(task.priority))
                            .frame(width: 12, height: 12)
                        Text(task.priority.displayName)
                            .font(.body)
                            .foregroundColor(AsaColors.darkSlate)
                    }
                }
                
                Divider()
                
                // 期日
                HStack {
                    Text("期日")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    
                    Spacer()
                    
                    if let dueDate = task.dueDate {
                        Text(formattedDateTime(dueDate))
                            .font(.body)
                            .foregroundColor(task.isOverdue ? .red : AsaColors.darkSlate)
                    } else {
                        Text("未設定")
                            .font(.body)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if isEditing {
                HStack(spacing: 12) {
                    AsaButton(
                        title: "キャンセル",
                        action: {
                            cancelEditing()
                        },
                        color: AsaColors.mutedSage
                    )
                    
                    AsaButton(
                        title: "保存",
                        action: {
                            viewModel.updateTask(
                                task,
                                title: editTitle,
                                description: editDescription.isEmpty ? nil : editDescription,
                                priority: editPriority,
                                dueDate: hasEditDueDate ? editDueDate : nil
                            )
                        },
                        isEnabled: !editTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            } else {
                statusActionButtons
            }
        }
    }
    
    private var statusActionButtons: some View {
        VStack(spacing: 8) {
            if task.status != .done {
                AsaButton(
                    title: "完了にする",
                    action: {
                        viewModel.moveTask(task, to: .done)
                        dismiss()
                    },
                    color: AsaColors.coffeeBrown
                )
            }
            
            if task.status == .todo {
                AsaButton(
                    title: "進行中にする",
                    action: {
                        viewModel.moveTask(task, to: .inProgress)
                        dismiss()
                    },
                    color: AsaColors.mocha
                )
            }
        }
    }
    
    private var editButton: some View {
        Button(isEditing ? "完了" : "編集") {
            if isEditing {
                viewModel.updateTask(
                    task,
                    title: editTitle,
                    description: editDescription.isEmpty ? nil : editDescription,
                    priority: editPriority,
                    dueDate: hasEditDueDate ? editDueDate : nil
                )
            } else {
                isEditing = true
            }
        }
        .foregroundColor(AsaColors.coffeeBrown)
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch task.status {
        case .todo: return AsaColors.mutedSage
        case .inProgress: return AsaColors.coffeeBrown
        case .done: return AsaColors.mocha
        }
    }
    
    // MARK: - Helper Methods
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return AsaColors.coffeeBrown
        case .low: return AsaColors.mutedSage
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func formattedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func cancelEditing() {
        editTitle = task.title
        editDescription = task.taskDescription ?? ""
        editPriority = task.priority
        editDueDate = task.dueDate
        hasEditDueDate = task.dueDate != nil
        isEditing = false
    }
    
    private func saveChanges() async {
        let finalDueDate = hasEditDueDate ? editDueDate : nil
        
        await viewModel.updateTask(
            task,
            title: editTitle,
            description: editDescription.isEmpty ? nil : editDescription,
            priority: editPriority,
            dueDate: finalDueDate
        )
        
        isEditing = false
    }
}

#Preview {
    TaskDetailView(
        task: Task(
            title: "API設計と実装",
            description: "RESTful APIの設計と実装を行う。認証機能とCRUD操作を含む。",
            priority: .high,
            dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
        )
    )
    .environmentObject(TaskBoardViewModel(dataService: try! TaskDataService.previewService()))
}
