//
//  TaskListView.swift
//  AsaSmartTodo
//
//  タスクリスト画面
//  タスク一覧表示とタスク追加機能
//

import SwiftUI
import AsaUIKit

struct TaskListView: View {
    @Bindable var viewModel: SmartTodoViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.tasks.isEmpty {
                    emptyStateView
                } else {
                    taskListView
                }
            }
            .navigationTitle("スマートToDo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showingAddTask = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddTask) {
                AddTaskView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Task List View

    private var taskListView: some View {
        List {
            // アクティブなタスク
            if !viewModel.activeTasks.isEmpty {
                Section("アクティブ") {
                    ForEach(viewModel.activeTasks, id: \.id) { task in
                        TaskRowView(task: task) {
                            viewModel.toggleTaskCompletion(task)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            viewModel.deleteTask(viewModel.activeTasks[index])
                        }
                    }
                }
            }

            // 完了済みタスク
            if !viewModel.completedTasks.isEmpty {
                Section("完了") {
                    ForEach(viewModel.completedTasks, id: \.id) { task in
                        TaskRowView(task: task) {
                            viewModel.toggleTaskCompletion(task)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            viewModel.deleteTask(viewModel.completedTasks[index])
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(AsaColors.mutedSage)

            Text("タスクがありません")
                .font(.title2)
                .fontWeight(.bold)

            Text("右上の + ボタンで\n新しいタスクを追加しましょう")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button(action: {
                viewModel.showingAddTask = true
            }) {
                Text("タスクを追加")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(AsaColors.coffeeBrown)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}
