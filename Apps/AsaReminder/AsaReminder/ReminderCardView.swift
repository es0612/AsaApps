//
//  ReminderCardView.swift
//  AsaReminder
//
//  Created on 2025/07/19
//

import SwiftUI

struct ReminderCardView: View {
    let reminder: Reminder
    let viewModel: ReminderViewModel
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー部分
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reminder.title)
                            .font(.headline)
                            .foregroundColor(Color("AsaDarkSlate"))
                            .strikethrough(reminder.isCompleted)
                        
                        if !reminder.content.isEmpty {
                            Text(reminder.content)
                                .font(.caption)
                                .foregroundColor(Color("AsaMutedSage"))
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    // 完了ボタン
                    Button(action: { viewModel.toggleCompletion(for: reminder) }) {
                        Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(reminder.isCompleted ? Color("AsaCoffeeBrown") : Color("AsaMutedSage"))
                            .font(.title2)
                    }
                }
                
                // 日時とステータス
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reminder.scheduledDate, style: .date)
                            .font(.caption)
                            .foregroundColor(Color("AsaMocha"))
                        
                        Text(reminder.scheduledDate, style: .time)
                            .font(.caption)
                            .foregroundColor(Color("AsaMocha"))
                    }
                    
                    Spacer()
                    
                    // ステータスインジケーター
                    HStack(spacing: 8) {
                        if reminder.hasNotification && !reminder.isCompleted {
                            Image(systemName: "bell.fill")
                                .foregroundColor(Color("AsaCoffeeBrown"))
                                .font(.caption)
                        }
                        
                        if reminder.isOverdue {
                            Text("期限切れ")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(8)
                        } else if !reminder.isCompleted {
                            Text(reminder.timeUntilDue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color("AsaSoftCream"))
                                .foregroundColor(Color("AsaMocha"))
                                .cornerRadius(8)
                        }
                    }
                }
                
                // アクションボタン
                HStack(spacing: 12) {
                    Spacer()
                    
                    Button(action: { viewModel.showEditSheet(for: reminder) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("編集")
                        }
                        .font(.caption)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    
                    Button(action: { viewModel.deleteReminder(reminder) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("削除")
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .opacity(reminder.isCompleted ? 0.6 : 1.0)
    }
}

#Preview {
    let sampleReminder = Reminder(
        title: "サンプルリマインダー",
        content: "これはサンプルの説明文です",
        scheduledDate: Date().addingTimeInterval(3600),
        hasNotification: true
    )
    
    return ReminderCardView(reminder: sampleReminder, viewModel: ReminderViewModel())
        .padding()
        .background(Color("AsaSoftCream"))
}