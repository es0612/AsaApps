//
//  TaskRowView.swift
//  AsaVoiceAssistant
//
//  タスク行コンポーネント
//

import SwiftUI
import AsaUIKit

/// タスク行ビュー
///
/// リスト内の1つのタスクを表示するコンポーネントです。
/// チェックボックス、タイトル、期限、優先度、カテゴリを表示します。
struct TaskRowView: View {
    // MARK: - Properties

    let task: VoiceTask
    let onToggleCompletion: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // チェックボックス
            Button(action: onToggleCompletion) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : AsaColors.mutedSage)
            }
            .buttonStyle(.plain)

            // タスク情報
            VStack(alignment: .leading, spacing: 4) {
                // タイトル
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(task.isCompleted ? AsaColors.mutedSage : AsaColors.darkSlate)
                    .strikethrough(task.isCompleted)
                    .lineLimit(2)

                // メタ情報
                HStack(spacing: 8) {
                    // カテゴリ
                    HStack(spacing: 4) {
                        Image(systemName: task.category.iconName)
                            .font(.caption2)
                        Text(task.category.displayName)
                            .font(.caption)
                    }
                    .foregroundColor(task.category.color)

                    // 期限
                    if let dueDateText = task.dueDateDisplayText {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(dueDateText)
                                .font(.caption)
                        }
                        .foregroundColor(task.isOverdue ? .red : AsaColors.mutedSage)
                    }

                    // 音声作成バッジ
                    if task.createdByVoice {
                        HStack(spacing: 2) {
                            Image(systemName: "mic.fill")
                                .font(.caption2)
                        }
                        .foregroundColor(AsaColors.coffeeBrown.opacity(0.6))
                    }
                }
            }

            Spacer()

            // 優先度インジケーター
            PriorityBadge(priority: task.priority)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("削除", systemImage: "trash")
            }
        }
    }
}

/// 優先度バッジ
struct PriorityBadge: View {
    let priority: PriorityLevel

    var body: some View {
        Text(priority.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(priority.color)
            )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        TaskRowView(
            task: {
                let task = VoiceTask(
                    title: "報告書を作成する",
                    priority: .high,
                    category: .work,
                    dueDate: Date().addingTimeInterval(86400),
                    createdByVoice: true
                )
                return task
            }(),
            onToggleCompletion: {},
            onDelete: {}
        )

        Divider()

        TaskRowView(
            task: {
                let task = VoiceTask(
                    title: "牛乳を買う",
                    priority: .medium,
                    category: .shopping
                )
                return task
            }(),
            onToggleCompletion: {},
            onDelete: {}
        )

        Divider()

        TaskRowView(
            task: {
                let task = VoiceTask(
                    title: "完了済みタスク",
                    priority: .low,
                    category: .personal
                )
                task.complete()
                return task
            }(),
            onToggleCompletion: {},
            onDelete: {}
        )
    }
    .background(AsaColors.softCream)
}
