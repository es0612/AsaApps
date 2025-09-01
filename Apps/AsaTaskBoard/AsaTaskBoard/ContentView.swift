import SwiftUI
import AsaUIKit
import AsaTaskKit

struct ContentView: View {
    @EnvironmentObject private var viewModel: TaskBoardViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景色
                AsaColors.softCream.opacity(0.3)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else {
                    mainContent
                }
            }
            .navigationTitle("AsaTaskBoard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addTaskButton
                }
            }
            .sheet(isPresented: $viewModel.showingAddTask) {
                AddTaskView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $viewModel.showingTaskDetail) {
                if let task = viewModel.selectedTask {
                    TaskDetailView(task: task)
                        .environmentObject(viewModel)
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .task {
                viewModel.loadBoard()
            }
        }
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("タスクボードを読み込み中...")
                .font(.headline)
                .foregroundColor(AsaColors.coffeeBrown)
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 16) {
            // プログレス表示
            if viewModel.totalTaskCount > 0 {
                progressCard
            }
            
            // Kanbanボード
            KanbanBoardView()
                .environmentObject(viewModel)
        }
        .padding()
    }
    
    private var progressCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("プロジェクト進捗")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    
                    Spacer()
                    
                    Text("\(viewModel.completedTaskCount)/\(viewModel.totalTaskCount)")
                        .font(.subheadline)
                        .foregroundColor(AsaColors.coffeeBrown)
                }
                
                ProgressView(value: viewModel.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: AsaColors.coffeeBrown))
                
                HStack {
                    if !viewModel.overdueTasks.isEmpty {
                        Label("\(viewModel.overdueTasks.count)件期限切れ", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.progressPercentage * 100))%完了")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
        }
    }
    
    private var addTaskButton: some View {
        Button {
            viewModel.prepareAddTask()
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .foregroundColor(AsaColors.coffeeBrown)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TaskBoardViewModel(dataService: try! TaskDataService.previewService()))
}
