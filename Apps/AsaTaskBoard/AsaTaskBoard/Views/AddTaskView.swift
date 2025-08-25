import SwiftUI
import AsaUIKit
import AsaTaskKit

struct AddTaskView: View {
    @EnvironmentObject private var viewModel: TaskBoardViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AsaColors.softCream.opacity(0.3)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // タイトル入力
                        titleSection
                        
                        // 説明入力
                        descriptionSection
                        
                        // 優先度選択
                        prioritySection
                        
                        // 期日設定
                        dueDateSection
                        
                        // 作成ボタン
                        createButton
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("新しいタスク")
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
    
    // MARK: - Views
    
    private var titleSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("タスク名")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)
                
                TextField("タスク名を入力", text: $viewModel.newTaskTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
    
    private var descriptionSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("説明（オプション）")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)
                
                TextField("説明を入力", text: $viewModel.newTaskDescription, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
        }
    }
    
    private var prioritySection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("優先度")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)
                
                Picker("優先度", selection: $viewModel.newTaskPriority) {
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
    }
    
    private var dueDateSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("期日")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    
                    Spacer()
                    
                    Toggle("", isOn: $viewModel.hasNewTaskDueDate)
                        .toggleStyle(SwitchToggleStyle(tint: AsaColors.coffeeBrown))
                }
                
                if viewModel.hasNewTaskDueDate {
                    DatePicker(
                        "期日を選択",
                        selection: Binding(
                            get: { viewModel.newTaskDueDate ?? Date() },
                            set: { viewModel.newTaskDueDate = $0 }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                }
            }
        }
    }
    
    private var createButton: some View {
        AsaButton(
            title: "タスクを作成",
            action: {
                Task {
                    await viewModel.addNewTask()
                    dismiss()
                }
            },
            isEnabled: !viewModel.newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        )
    }
    
    // MARK: - Helper Methods
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return AsaColors.coffeeBrown
        case .low: return AsaColors.mutedSage
        }
    }
}

#Preview {
    AddTaskView()
        .environmentObject(TaskBoardViewModel(dataService: try! TaskDataService.previewService()))
}