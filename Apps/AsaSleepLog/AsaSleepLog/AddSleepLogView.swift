//
//  AddSleepLogView.swift
//  AsaSleepLog
//  
//  Created on 2025/06/26
//

import SwiftUI

struct AddSleepLogView: View {
    @ObservedObject var viewModel: SleepLogViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ScrollView {
                    VStack(spacing: 20) {
                        TimeSettingSection(
                            bedTime: $viewModel.bedTime,
                            wakeTime: $viewModel.wakeTime
                        )
                        .padding(.horizontal)
                        
                        SleepQualitySection(selectedQuality: $viewModel.selectedQuality)
                            .padding(.horizontal)
                        
                        NotesSection(notes: $viewModel.notes)
                            .padding(.horizontal)
                    }
                }
                
                AsaButton(title: "記録を保存") {
                    viewModel.addSleepLog()
                    dismiss()
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("睡眠記録を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NotesSection: View {
    @Binding var notes: String
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("メモ（任意）")
                    .font(.headline)
                Spacer()
            }
            
            TextField("睡眠に関するメモを入力...", text: $notes)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(10)
    }
}

#Preview {
    AddSleepLogView(viewModel: SleepLogViewModel())
}