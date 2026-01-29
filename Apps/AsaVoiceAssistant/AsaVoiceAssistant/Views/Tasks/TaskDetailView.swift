//
//  TaskDetailView.swift
//  AsaVoiceAssistant
//
//  タスク詳細画面
//

import SwiftUI
import AsaUIKit

/// タスク詳細画面
///
/// タスクの詳細情報を表示し、編集や削除を行える画面です。
struct TaskDetailView: View {
    // MARK: - Properties

    let task: VoiceTask
    let onUpdate: (VoiceTask) -> Void
    let onDelete: () -> Void
    let onToggleCompletion: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var editTitle: String = ""
    @State private var editDescription: String = ""
    @State private var editPriority: PriorityLevel = .medium
    @State private var editCategory: TaskCategory = .other
    @State private var editHasDueDate: Bool = false
    @State private var editDueDate: Date = Date()

    @State private var showingDeleteConfirmation = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AsaColors.softCream
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // ステータスカード
                        statusCard

                        // 詳細カード
                        detailCard

                        // 音声認識情報（音声で作成された場合）
                        if task.createdByVoice, let transcription = task.originalTranscription {
                            voiceInfoCard(transcription: transcription)
                        }

                        // アクションボタン
                        actionButtons
                    }
                    .padding(20)
                }
            }
            .navigationTitle("タスク詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "保存" : "編集") {
                        if isEditing {
                            saveChanges()
                        } else {
                            startEditing()
                        }
                    }
                }
            }
            .alert("タスクを削除", isPresented: $showingDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("「\(task.title)」を削除しますか？この操作は取り消せません。")
            }
        }
    }

    // MARK: - Subviews

    private var statusCard: some View {
        VStack(spacing: 12) {
            // 完了状態
            HStack {
                Button(action: onToggleCompletion) {
                    HStack(spacing: 8) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(task.isCompleted ? .green : AsaColors.mutedSage)

                        Text(task.isCompleted ? "完了済み" : "未完了")
                            .font(.headline)
                            .foregroundColor(task.isCompleted ? .green : AsaColors.darkSlate)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // 優先度バッジ
                if isEditing {
                    Picker("優先度", selection: $editPriority) {
                        ForEach(PriorityLevel.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                } else {
                    PriorityBadge(priority: task.priority)
                }
            }

            // 完了日時
            if task.isCompleted, let completedAt = task.completedAt {
                HStack {
                    Text("完了日時:")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)

                    Text(formatDateTime(completedAt))
                        .font(.caption)
                        .foregroundColor(AsaColors.darkSlate)

                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // タイトル
            VStack(alignment: .leading, spacing: 4) {
                Text("タイトル")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)

                if isEditing {
                    TextField("タイトル", text: $editTitle)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Text(task.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(AsaColors.darkSlate)
                }
            }

            Divider()

            // 説明
            VStack(alignment: .leading, spacing: 4) {
                Text("説明")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)

                if isEditing {
                    TextField("説明（オプション）", text: $editDescription, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...5)
                } else {
                    Text(task.taskDescription ?? "なし")
                        .font(.body)
                        .foregroundColor(task.taskDescription != nil ? AsaColors.darkSlate : AsaColors.mutedSage)
                }
            }

            Divider()

            // カテゴリ
            VStack(alignment: .leading, spacing: 4) {
                Text("カテゴリ")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)

                if isEditing {
                    Picker("カテゴリ", selection: $editCategory) {
                        ForEach(TaskCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: task.category.iconName)
                            .foregroundColor(task.category.color)
                        Text(task.category.displayName)
                            .font(.body)
                            .foregroundColor(AsaColors.darkSlate)
                    }
                }
            }

            Divider()

            // 期限
            VStack(alignment: .leading, spacing: 4) {
                Text("期限")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)

                if isEditing {
                    Toggle("期限を設定", isOn: $editHasDueDate)

                    if editHasDueDate {
                        DatePicker("期限", selection: $editDueDate, displayedComponents: .date)
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundColor(task.isOverdue ? .red : AsaColors.mutedSage)
                        Text(task.dueDateDisplayText ?? "なし")
                            .font(.body)
                            .foregroundColor(task.isOverdue ? .red : AsaColors.darkSlate)
                    }
                }
            }

            Divider()

            // 作成日時
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("作成日時")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)

                    Text(formatDateTime(task.createdAt))
                        .font(.body)
                        .foregroundColor(AsaColors.darkSlate)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("更新日時")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)

                    Text(formatDateTime(task.updatedAt))
                        .font(.body)
                        .foregroundColor(AsaColors.darkSlate)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }

    private func voiceInfoCard(transcription: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundColor(AsaColors.coffeeBrown)
                Text("音声で作成")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AsaColors.coffeeBrown)
            }

            Text("「\(transcription)」")
                .font(.body)
                .italic()
                .foregroundColor(AsaColors.darkSlate.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AsaColors.coffeeBrown.opacity(0.1))
        )
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 完了/未完了切り替え
            Button(action: onToggleCompletion) {
                HStack {
                    Image(systemName: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                    Text(task.isCompleted ? "未完了に戻す" : "完了にする")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(task.isCompleted ? AsaColors.mutedSage : .green)
                )
            }

            // 削除
            Button(action: { showingDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("削除")
                }
                .font(.headline)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.red, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Helper

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func startEditing() {
        editTitle = task.title
        editDescription = task.taskDescription ?? ""
        editPriority = task.priority
        editCategory = task.category
        editHasDueDate = task.dueDate != nil
        editDueDate = task.dueDate ?? Date()
        isEditing = true
    }

    private func saveChanges() {
        task.update(
            title: editTitle,
            description: editDescription.isEmpty ? nil : editDescription,
            priority: editPriority,
            category: editCategory,
            dueDate: editHasDueDate ? editDueDate : nil
        )
        onUpdate(task)
        isEditing = false
    }
}

// MARK: - Preview

#Preview {
    let task = VoiceTask(
        title: "報告書を作成する",
        description: "月次レポートの作成",
        priority: .high,
        category: .work,
        dueDate: Date().addingTimeInterval(86400),
        originalTranscription: "明日までに報告書を作成する",
        createdByVoice: true
    )

    return TaskDetailView(
        task: task,
        onUpdate: { _ in },
        onDelete: {},
        onToggleCompletion: {}
    )
}
