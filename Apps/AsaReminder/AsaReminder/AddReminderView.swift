//
//  AddReminderView.swift
//  AsaReminder
//
//  Created on 2025/07/19
//

import SwiftUI

struct AddReminderView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: ReminderViewModel
    
    @State private var title = ""
    @State private var content = ""
    @State private var scheduledDate = Date().addingTimeInterval(3600) // 1時間後
    @State private var hasNotification = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    AsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("新しいリマインダー")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("AsaDarkSlate"))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("タイトル")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaMocha"))
                                
                                TextField("例: 会議の準備", text: $title)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("説明（オプション）")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaMocha"))
                                
                                TextField("詳細を入力してください", text: $content, axis: .vertical)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .lineLimit(3...6)
                            }
                        }
                    }
                    
                    AsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("日時設定")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("AsaDarkSlate"))
                            
                            DatePicker(
                                "リマインダー日時",
                                selection: $scheduledDate,
                                in: Date()...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(GraphicalDatePickerStyle())
                            
                            Toggle("通知を有効にする", isOn: $hasNotification)
                                .font(.headline)
                                .foregroundColor(Color("AsaMocha"))
                        }
                    }
                    
                    VStack(spacing: 12) {
                        AsaButton(
                            title: "リマインダーを作成",
                            action: saveReminder,
                            color: Color("AsaCoffeeBrown"),
                            isEnabled: !title.isEmpty
                        )
                        
                        AsaButton(
                            title: "キャンセル",
                            action: { dismiss() },
                            color: Color("AsaMutedSage")
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("新規作成")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func saveReminder() {
        viewModel.addReminder(
            title: title,
            content: content,
            scheduledDate: scheduledDate,
            hasNotification: hasNotification
        )
        viewModel.hideAddSheet()
        dismiss()
    }
}

#Preview {
    AddReminderView(viewModel: ReminderViewModel())
}