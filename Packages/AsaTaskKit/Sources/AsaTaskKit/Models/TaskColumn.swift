import Foundation
import SwiftData
import AsaUIKit

@Model
public final class TaskColumn {
    public var id: UUID
    public var title: String
    public var statusRawValue: String
    public var position: Int
    public var createdAt: Date
    
    // Computed property for enum access
    public var status: TaskStatus {
        get { TaskStatus(rawValue: statusRawValue) ?? .todo }
        set { statusRawValue = newValue.rawValue }
    }
    
    // リレーション
    @Relationship(deleteRule: .cascade, inverse: \Task.column)
    public var tasks: [Task] = []
    
    public var board: TaskBoard?
    
    public init(
        title: String,
        status: TaskStatus,
        position: Int
    ) {
        self.id = UUID()
        self.title = title
        self.statusRawValue = status.rawValue
        self.position = position
        self.createdAt = Date()
    }
    
    // MARK: - Computed Properties
    
    public var taskCount: Int {
        tasks.count
    }
    
    public var completedTaskCount: Int {
        tasks.filter { $0.status == .done }.count
    }
    
    public var highPriorityTaskCount: Int {
        tasks.filter { $0.priority == .high }.count
    }
    
    public var overdueTaskCount: Int {
        tasks.filter { $0.isOverdue }.count
    }
    
    // MARK: - Methods
    
    public func addTask(_ task: Task) {
        task.column = self
        task.status = self.status
        tasks.append(task)
    }
    
    public func removeTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        task.column = nil
    }
    
    public func moveTask(_ task: Task, to targetColumn: TaskColumn) {
        removeTask(task)
        targetColumn.addTask(task)
    }
    
    public func reorderTasks() {
        tasks.sort { task1, task2 in
            // 優先度順（高→中→低）、次に作成日時順（新→古）
            if task1.priority != task2.priority {
                return task1.priority.rawValue < task2.priority.rawValue
            }
            return task1.createdAt > task2.createdAt
        }
    }
}