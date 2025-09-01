import SwiftUI
import AsaUIKit
import AsaTaskKit

struct TaskColumnView: View {
    let title: String
    let tasks: [Task]
    let status: TaskStatus
    let color: Color
    
    @EnvironmentObject private var viewModel: TaskBoardViewModel
    @State private var isDragOver = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // カラムヘッダー
            columnHeader
            
            // タスクリスト
            LazyVStack(spacing: 8) {
                ForEach(tasks, id: \.id) { task in
                    TaskCardView(task: task)
                        .environmentObject(viewModel)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            
            Spacer(minLength: 20)
        }
        .frame(width: 280)
        .padding()
        .background(color.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .scaleEffect(isDragOver ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDragOver)
        .dropDestination(for: TaskDropItem.self) { items, location in
            handleDrop(items: items)
        } isTargeted: { targeted in
            isDragOver = targeted
        }
    }
    
    // MARK: - Views
    
    private var columnHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AsaColors.darkSlate)
                
                Text("\(tasks.count)件")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
            
            Spacer()
            
            if status != .done && hasHighPriorityTasks {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
            
            if hasOverdueTasks {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Computed Properties
    
    private var hasHighPriorityTasks: Bool {
        tasks.contains { $0.priority == .high }
    }
    
    private var hasOverdueTasks: Bool {
        tasks.contains { $0.isOverdue }
    }
    
    // MARK: - Methods
    
    private func handleDrop(items: [TaskDropItem]) -> Bool {
        guard let item = items.first,
              let task = findTask(by: item.taskId),
              viewModel.canDrop(task: task, to: status) else {
            return false
        }
        
        viewModel.moveTask(task, to: status)
        viewModel.endDragging()
        
        return true
    }
    
    private func findTask(by id: UUID) -> AsaTaskKit.Task? {
        return viewModel.currentBoard?.allTasks.first { $0.id == id }
    }
}

// MARK: - Drag & Drop Support

struct TaskDropItem: Transferable, Codable {
    let taskId: UUID
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

#Preview {
    HStack {
        TaskColumnView(
            title: "To Do",
            tasks: [],
            status: .todo,
            color: AsaColors.todoColumn
        )
        
        TaskColumnView(
            title: "進行中",
            tasks: [],
            status: .inProgress,
            color: AsaColors.inProgressColumn
        )
        
        TaskColumnView(
            title: "完了",
            tasks: [],
            status: .done,
            color: AsaColors.doneColumn
        )
    }
    .environmentObject(TaskBoardViewModel(dataService: try! TaskDataService.previewService()))
}
