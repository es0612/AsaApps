import SwiftUI
import AsaUIKit

struct TaskDetailView: View {
    let task: SmartTask
    @EnvironmentObject private var viewModel: SmartTodoViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var editMode = false
    @State private var editedTitle: String = ""
    @State private var editedDescription: String = ""
    @State private var editedCategory: TaskCategory = .other
    @State private var editedDueDate: Date? = nil
    @State private var editedPriority: TaskPriority = .medium
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                AsaColors.softCream.opacity(0.3)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // ステータスセクション
                        statusSection

                        // AI予測セクション
                        if !task.feedbackProvided && task.aiSuggestedPriority != task.userPriority {
                            aiPredictionSection
                        }

                        // 詳細情報セクション
                        if editMode {
                            editableDetailsSection
                        } else {
                            detailsSection
                        }

                        // アクションボタン
                        actionButtons
                    }
                    .padding()
                }
            }
            .navigationTitle("タスク詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .onAppear {
                setupEditValues()
            }
            .confirmationDialog(
                "タスクを削除しますか？",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    deleteTask()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("この操作は取り消せません")
            }
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        AsaCard {
            VStack(spacing: 16) {
                // タイトルと優先度
                HStack {
                    Circle()
                        .fill(priorityColor(task.userPriority))
                        .frame(width: 12, height: 12)

                    Text(task.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AsaColors.darkSlate)

                    Spacer()

                    TaskStatusBadge(status: task.status)
                }

                // メタ情報
                HStack(spacing: 20) {
                    MetaInfoItem(
                        icon: "calendar",
                        text: formatDate(task.createdAt),
                        label: "作成日"
                    )

                    if let dueDate = task.dueDate {
                        MetaInfoItem(
                            icon: "calendar.badge.exclamationmark",
                            text: formatDate(dueDate),
                            label: "期限",
                            isHighlighted: task.isOverdue
                        )
                    }

                    if let completedAt = task.completedAt {
                        MetaInfoItem(
                            icon: "checkmark.circle",
                            text: formatDate(completedAt),
                            label: "完了日"
                        )
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - AI Prediction Section

    private var aiPredictionSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "brain")
                        .foregroundColor(AsaColors.mocha)
                    Text("AI優先度提案")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    Spacer()
                    Text("信頼度: \(Int(task.confidenceScore * 100))%")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }

                // 現在と提案の比較
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("現在の優先度")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                        PriorityDisplay(priority: task.userPriority)
                    }

                    Image(systemName: "arrow.right")
                        .foregroundColor(AsaColors.mutedSage)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI提案")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                        PriorityDisplay(priority: task.aiSuggestedPriority)
                    }
                }

                // 理由
                Text(task.predictionReason)
                    .font(.caption)
                    .foregroundColor(AsaColors.darkSlate.opacity(0.8))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(AsaColors.softCream)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // フィードバックボタン
                HStack(spacing: 12) {
                    AsaButton(
                        title: "採用する",
                        action: {
                            viewModel.acceptAIPriority(for: task)
                            dismiss()
                        },
                        color: AsaColors.coffeeBrown,
                        size: .small
                    )

                    Button("却下する") {
                        viewModel.rejectAIPriority(for: task)
                    }
                    .foregroundColor(AsaColors.mutedSage)
                    .font(.subheadline)
                }
            }
            .padding()
        }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(spacing: 16) {
            // 説明
            if let description = task.taskDescription, !description.isEmpty {
                AsaCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("説明", systemImage: "text.alignleft")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)

                        Text(description)
                            .font(.body)
                            .foregroundColor(AsaColors.darkSlate)
                    }
                    .padding()
                }
            }

            // カテゴリと優先度
            AsaCard {
                HStack(spacing: 30) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("カテゴリ", systemImage: "folder")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)

                        HStack {
                            Image(systemName: categoryIcon(task.category))
                            Text(task.category.rawValue)
                        }
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("優先度", systemImage: "flag")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)

                        PriorityDisplay(priority: task.userPriority)
                    }

                    Spacer()
                }
                .padding()
            }

            // 学習データ
            if task.feedbackProvided {
                AsaCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("学習データ", systemImage: "graduationcap")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)

                        HStack(spacing: 16) {
                            LearningDataItem(
                                label: "予測精度",
                                value: "\(Int(task.confidenceScore * 100))%"
                            )
                            LearningDataItem(
                                label: "フィードバック",
                                value: task.feedbackIsPositive ?? false ? "採用" : "却下"
                            )
                            LearningDataItem(
                                label: "作成時刻",
                                value: "\(task.createdHour)時"
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Editable Details Section

    private var editableDetailsSection: some View {
        VStack(spacing: 16) {
            // タイトル編集
            AsaCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("タスク名", systemImage: "pencil")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)

                    TextField("タスク名", text: $editedTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
            }

            // 説明編集
            AsaCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("説明", systemImage: "text.alignleft")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)

                    TextEditor(text: $editedDescription)
                        .frame(minHeight: 100)
                        .padding(4)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding()
            }

            // カテゴリと優先度編集
            AsaCard {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("カテゴリ", systemImage: "folder")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)

                        Picker("カテゴリ", selection: $editedCategory) {
                            ForEach(TaskCategory.allCases, id: \.self) { cat in
                                Text(cat.rawValue).tag(cat)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("優先度", systemImage: "flag")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)

                        Picker("優先度", selection: $editedPriority) {
                            ForEach([TaskPriority.high, .medium, .low], id: \.self) { priority in
                                Text(priority.displayName).tag(priority)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                .padding()
            }

            // 期限編集
            AsaCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("期限", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)

                    if editedDueDate != nil {
                        DatePicker(
                            "期限",
                            selection: Binding(
                                get: { editedDueDate ?? Date() },
                                set: { editedDueDate = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()

                        Button("期限をクリア") {
                            editedDueDate = nil
                        }
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                    } else {
                        Button("期限を設定") {
                            editedDueDate = Date()
                        }
                        .foregroundColor(AsaColors.coffeeBrown)
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if task.status != .done {
                AsaButton(
                    title: "タスクを完了",
                    action: {
                        viewModel.completeTask(task)
                        dismiss()
                    },
                    color: AsaColors.coffeeBrown
                )
            }

            if editMode {
                HStack(spacing: 12) {
                    AsaButton(
                        title: "保存",
                        action: saveChanges,
                        color: AsaColors.coffeeBrown
                    )

                    Button("キャンセル") {
                        editMode = false
                        setupEditValues()
                    }
                    .foregroundColor(AsaColors.mutedSage)
                }
            }

            Button("タスクを削除") {
                showDeleteConfirmation = true
            }
            .foregroundColor(Color.red)
            .padding(.top, 20)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("閉じる") {
                dismiss()
            }
            .foregroundColor(AsaColors.coffeeBrown)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            if !editMode && task.status != .done {
                Button("編集") {
                    editMode = true
                }
                .foregroundColor(AsaColors.coffeeBrown)
            }
        }
    }

    // MARK: - Helper Methods

    private func setupEditValues() {
        editedTitle = task.title
        editedDescription = task.taskDescription ?? ""
        editedCategory = task.category
        editedDueDate = task.dueDate
        editedPriority = task.userPriority
    }

    private func saveChanges() {
        task.updateDetails(
            title: editedTitle.isEmpty ? nil : editedTitle,
            description: editedDescription.isEmpty ? nil : editedDescription,
            category: editedCategory,
            dueDate: editedDueDate
        )
        task.userPriority = editedPriority

        Task {
            await viewModel.updateTask(task)
            await MainActor.run {
                editMode = false
            }
        }
    }

    private func deleteTask() {
        viewModel.deleteTask(task)
        dismiss()
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
            formatter.dateFormat = "HH:mm"
            return "今日 " + formatter.string(from: date)
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.dateFormat = "HH:mm"
            return "昨日 " + formatter.string(from: date)
        } else if Calendar.current.isDateInTomorrow(date) {
            formatter.dateFormat = "HH:mm"
            return "明日 " + formatter.string(from: date)
        } else {
            formatter.dateFormat = "M月d日 HH:mm"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Supporting Views

struct TaskStatusBadge: View {
    let status: TaskStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var statusColor: Color {
        switch status {
        case .todo:
            return AsaColors.mutedSage
        case .inProgress:
            return AsaColors.mocha
        case .done:
            return AsaColors.coffeeBrown
        case .cancelled:
            return Color.gray
        }
    }
}

struct MetaInfoItem: View {
    let icon: String
    let text: String
    let label: String
    var isHighlighted: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(isHighlighted ? Color.red : AsaColors.mutedSage)
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isHighlighted ? Color.red : AsaColors.darkSlate)
            Text(label)
                .font(.caption2)
                .foregroundColor(AsaColors.mutedSage)
        }
    }
}

struct PriorityDisplay: View {
    let priority: TaskPriority

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            Text(priority.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(priorityColor)
        }
    }

    private var priorityColor: Color {
        switch priority {
        case .high:
            return Color.red
        case .medium:
            return AsaColors.coffeeBrown
        case .low:
            return AsaColors.mutedSage
        }
    }
}

struct LearningDataItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(AsaColors.mutedSage)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(AsaColors.darkSlate)
        }
    }
}

// MARK: - Preview

#Preview {
    let task = SmartTask(
        title: "サンプルタスク",
        description: "これはサンプルタスクの説明です",
        category: .work,
        dueDate: Date().addingTimeInterval(86400)
    )
    task.aiSuggestedPriority = .high
    task.confidenceScore = 0.85
    task.predictionReason = "期限が近く、仕事関連のタスクのため高優先度を推奨"

    return TaskDetailView(task: task)
        .environmentObject(SmartTodoViewModel())
}