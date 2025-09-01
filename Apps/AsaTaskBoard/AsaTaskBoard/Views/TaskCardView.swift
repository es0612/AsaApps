import SwiftUI
import AsaUIKit
import AsaTaskKit

struct TaskCardView: View {
    let task: Task
    
    @EnvironmentObject private var viewModel: TaskBoardViewModel
    @State private var isDragging = false
    
    var body: some View {
        AsaKanbanCard(
            title: task.title,
            description: task.taskDescription,
            priority: task.priority,
            dueDate: task.dueDate
        ) {
            viewModel.selectTask(task)
        }
        .draggableCardStyle(isDragging: isDragging)
        .draggable(TaskDropItem(taskId: task.id)) {
            cardPreview
        }
        .onDrag {
            viewModel.startDragging(task)
            isDragging = true
            return NSItemProvider(object: task.id.uuidString as NSString)
        }
        .contextMenu {
            contextMenuItems
        }
    }
    
    // MARK: - Views
    
    private var cardPreview: some View {
        AsaKanbanCard(
            title: task.title,
            description: task.taskDescription,
            priority: task.priority,
            dueDate: task.dueDate
        )
        .frame(width: 260)
        .opacity(0.8)
    }
    
    private var contextMenuItems: some View {
        Group {
            Button {
                viewModel.selectTask(task)
            } label: {
                Label("詳細を表示", systemImage: "info.circle")
            }
            
            if task.status != .inProgress {
                Button {
                    viewModel.moveTask(task, to: .inProgress)
                } label: {
                    Label("進行中に移動", systemImage: "arrow.right.circle")
                }
            }
            
            if task.status != .done {
                Button {
                    viewModel.moveTask(task, to: .done)
                } label: {
                    Label("完了に移動", systemImage: "checkmark.circle")
                }
            }
            
            Divider()
            
            Button(role: .destructive) {
                viewModel.deleteTask(task)
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        TaskCardView(
            task: Task(
                title: "API設計",
                description: "RESTful APIの設計と実装",
                priority: .high,
                dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
            )
        )
        
        TaskCardView(
            task: Task(
                title: "UI改善",
                priority: .medium
            )
        )
        
        TaskCardView(
            task: Task(
                title: "テスト作成",
                description: "ユニットテストとUIテストの作成",
                priority: .low,
                dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())
            )
        )
    }
    .padding()
    .background(AsaColors.softCream)
    .environmentObject(TaskBoardViewModel(dataService: try! TaskDataService.previewService()))
}
