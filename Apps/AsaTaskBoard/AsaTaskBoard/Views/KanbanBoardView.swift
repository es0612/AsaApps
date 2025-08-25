import SwiftUI
import AsaUIKit
import AsaTaskKit

struct KanbanBoardView: View {
    @EnvironmentObject private var viewModel: TaskBoardViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                // To Do カラム
                TaskColumnView(
                    title: "To Do",
                    tasks: viewModel.todoTasks,
                    status: .todo,
                    color: AsaColors.todoColumn
                )
                .environmentObject(viewModel)
                
                // 進行中 カラム
                TaskColumnView(
                    title: "進行中",
                    tasks: viewModel.inProgressTasks,
                    status: .inProgress,
                    color: AsaColors.inProgressColumn
                )
                .environmentObject(viewModel)
                
                // 完了 カラム
                TaskColumnView(
                    title: "完了",
                    tasks: viewModel.doneTasks,
                    status: .done,
                    color: AsaColors.doneColumn
                )
                .environmentObject(viewModel)
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    KanbanBoardView()
        .environmentObject(TaskBoardViewModel(dataService: try! TaskDataService.previewService()))
}