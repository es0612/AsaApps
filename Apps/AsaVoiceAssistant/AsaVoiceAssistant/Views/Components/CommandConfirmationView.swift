//
//  CommandConfirmationView.swift
//  AsaVoiceAssistant
//
//  コマンド確認ダイアログコンポーネント
//

import SwiftUI
import AsaUIKit

/// コマンド確認ダイアログビュー
///
/// 解析されたコマンドの内容を表示し、実行または取消を選択させます。
struct CommandConfirmationView: View {
    // MARK: - Properties

    let command: VoiceCommand
    let onConfirm: () -> Void
    let onCancel: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // ヘッダー
            VStack(spacing: 8) {
                Image(systemName: command.intent.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(AsaColors.coffeeBrown)

                Text("コマンドを確認")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)
            }

            // コマンド詳細
            VStack(alignment: .leading, spacing: 12) {
                // インテント
                DetailRow(label: "操作", value: command.intent.displayName)

                // タスクタイトル（作成時）
                if let title = command.taskTitle {
                    DetailRow(label: "タスク", value: "「\(title)」")
                }

                // 対象タスク（完了・削除時）
                if let query = command.targetTaskQuery {
                    DetailRow(label: "対象", value: "「\(query)」")
                }

                // 期限
                if let dueDate = command.dueDate {
                    DetailRow(label: "期限", value: formatDate(dueDate))
                }

                // 優先度
                if let priority = command.priority {
                    DetailRow(label: "優先度", value: priority.displayName, color: priority.color)
                }

                // カテゴリ
                if let category = command.category {
                    DetailRow(label: "カテゴリ", value: category.displayName)
                }

                // フィルター（一覧・読み上げ時）
                if command.intent == .listTasks || command.intent == .readTasks {
                    if let filterPriority = command.filterPriority {
                        DetailRow(label: "フィルター", value: "\(filterPriority.displayName)優先度")
                    }
                    if let filterCategory = command.filterCategory {
                        DetailRow(label: "フィルター", value: filterCategory.displayName)
                    }
                }

                // 信頼度
                DetailRow(
                    label: "信頼度",
                    value: "\(Int(command.confidence * 100))%",
                    color: confidenceColor(command.confidence)
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )

            // 元のテキスト
            VStack(alignment: .leading, spacing: 4) {
                Text("認識テキスト")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)

                Text("\"\(command.rawTranscription)\"")
                    .font(.subheadline)
                    .foregroundColor(AsaColors.darkSlate.opacity(0.7))
                    .italic()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            // ボタン
            HStack(spacing: 16) {
                // キャンセルボタン
                Button(action: onCancel) {
                    Text("キャンセル")
                        .font(.headline)
                        .foregroundColor(AsaColors.mutedSage)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AsaColors.mutedSage, lineWidth: 1)
                        )
                }

                // 実行ボタン
                Button(action: onConfirm) {
                    Text("実行")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AsaColors.coffeeBrown)
                        )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AsaColors.softCream)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Helper

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

/// 詳細行コンポーネント
struct DetailRow: View {
    let label: String
    let value: String
    var color: Color = AsaColors.darkSlate

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        CommandConfirmationView(
            command: VoiceCommand(
                intent: .createTask,
                taskTitle: "報告書を作成する",
                priority: .high,
                category: .work,
                dueDate: Date().addingTimeInterval(86400),
                rawTranscription: "明日までに報告書を作成する",
                confidence: 0.85
            ),
            onConfirm: {},
            onCancel: {}
        )
    }
}
