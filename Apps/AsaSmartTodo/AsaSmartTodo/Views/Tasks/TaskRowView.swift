//
//  TaskRowView.swift
//  AsaSmartTodo
//
//  タスクリストの行表示
//  優先度、カテゴリ、期限、AI予測状態を表示
//

import SwiftUI
import AsaUIKit

struct TaskRowView: View {
    let task: SmartTask
    let onToggleComplete: () -> Void
    let onShowAIDetail: (() -> Void)?

    init(task: SmartTask, onToggleComplete: @escaping () -> Void, onShowAIDetail: (() -> Void)? = nil) {
        self.task = task
        self.onToggleComplete = onToggleComplete
        self.onShowAIDetail = onShowAIDetail
    }

    var body: some View {
        HStack(spacing: 12) {
            // 完了チェックボックス
            Button(action: onToggleComplete) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : AsaColors.mutedSage)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                // タイトルと優先度
                HStack(spacing: 6) {
                    Text(task.finalPriority.icon)
                        .font(.caption)

                    Text(task.title)
                        .font(.headline)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)

                    Spacer()
                }

                // カテゴリと期限
                HStack(spacing: 8) {
                    // カテゴリ
                    HStack(spacing: 4) {
                        Text(task.category.icon)
                        Text(task.category.displayName)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    // 期限表示
                    if let dueDate = task.dueDate {
                        Divider()
                            .frame(height: 12)

                        HStack(spacing: 4) {
                            Image(systemName: task.isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                            Text(dueDate, format: .dateTime.month().day())
                        }
                        .font(.caption)
                        .foregroundColor(task.isOverdue ? .red : .secondary)
                    }

                    Spacer()

                    // AI予測インジケータ（タップ可能）
                    if task.aiPriority != nil {
                        Button(action: {
                            onShowAIDetail?()
                        }) {
                            HStack(spacing: 2) {
                                Image(systemName: "brain.head.profile")
                                Text("\(task.confidenceScore, format: .percent.precision(.fractionLength(0)))")
                            }
                            .font(.caption2)
                            .foregroundColor(AsaColors.coffeeBrown)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AsaColors.softCream)
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}
