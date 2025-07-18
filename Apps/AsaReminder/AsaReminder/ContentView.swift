//
//  ContentView.swift
//  AsaReminder
//  
//  Created on 2025/07/19
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ReminderViewModel()
    @State private var selectedSegment = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // セグメント選択
                Picker("表示", selection: $selectedSegment) {
                    Text("予定").tag(0)
                    Text("完了").tag(1)
                    Text("期限切れ").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // リマインダーリスト
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredReminders) { reminder in
                            ReminderCardView(reminder: reminder, viewModel: viewModel)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("リマインダー")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.showAddSheet) {
                        Image(systemName: "plus")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddSheet) {
                AddReminderView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isShowingEditSheet) {
                if let reminder = viewModel.selectedReminder {
                    EditReminderView(reminder: reminder, viewModel: viewModel)
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
    }
    
    private var filteredReminders: [Reminder] {
        switch selectedSegment {
        case 0: return viewModel.pendingReminders
        case 1: return viewModel.completedReminders
        case 2: return viewModel.overdueReminders
        default: return viewModel.reminders
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Reminder.self, inMemory: true)
}
