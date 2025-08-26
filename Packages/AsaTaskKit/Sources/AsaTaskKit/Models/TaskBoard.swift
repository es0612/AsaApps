import Foundation
import SwiftData
import AsaUIKit

@Model
public final class TaskBoard {
    public var id: UUID
    public var title: String
    public var boardDescription: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    // リレーション
    @Relationship(deleteRule: .cascade, inverse: \TaskColumn.board)
    public var columns: [TaskColumn] = []
    
    public init(
        title: String,
        description: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.boardDescription = description
        self.createdAt = Date()
        self.updatedAt = Date()
        
        // デフォルトカラムを作成
        setupDefaultColumns()
    }
    
    // MARK: - Setup Methods
    
    private func setupDefaultColumns() {
        let todoColumn = TaskColumn(
            title: "To Do",
            status: .todo,
            position: 0
        )
        
        let inProgressColumn = TaskColumn(
            title: "進行中",
            status: .inProgress,
            position: 1
        )
        
        let doneColumn = TaskColumn(
            title: "完了",
            status: .done,
            position: 2
        )
        
        todoColumn.board = self
        inProgressColumn.board = self
        doneColumn.board = self
        
        columns = [todoColumn, inProgressColumn, doneColumn]
    }
    
    // MARK: - Computed Properties
    
    public var totalTaskCount: Int {
        columns.reduce(0) { $0 + $1.taskCount }
    }
    
    public var completedTaskCount: Int {
        columns.reduce(0) { $0 + $1.completedTaskCount }
    }
    
    public var progressPercentage: Double {
        guard totalTaskCount > 0 else { return 0 }
        return Double(completedTaskCount) / Double(totalTaskCount)
    }
    
    public var overdueTaskCount: Int {
        columns.reduce(0) { $0 + $1.overdueTaskCount }
    }
    
    public var allTasks: [Task] {
        columns.flatMap { $0.tasks }
    }
    
    // MARK: - Methods
    
    public func addTask(_ task: Task, to columnStatus: TaskStatus = .todo) {
        guard let targetColumn = columns.first(where: { $0.status == columnStatus }) else {
            return
        }
        targetColumn.addTask(task)
        updatedAt = Date()
    }
    
    public func moveTask(_ task: Task, to targetColumnStatus: TaskStatus) {
        guard let currentColumn = task.column,
              let targetColumn = columns.first(where: { $0.status == targetColumnStatus }),
              currentColumn != targetColumn else {
            return
        }
        
        currentColumn.moveTask(task, to: targetColumn)
        updatedAt = Date()
    }
    
    public func deleteTask(_ task: Task) {
        task.column?.removeTask(task)
        updatedAt = Date()
    }
    
    public func reorderAllColumns() {
        columns.forEach { $0.reorderTasks() }
    }
    
    public func getColumn(for status: TaskStatus) -> TaskColumn? {
        return columns.first { $0.status == status }
    }
    
    // 統計メソッド
    public func getTasksByPriority(_ priority: AsaTaskPriority) -> [AsaTaskKit.Task] {
        return allTasks.filter { $0.priority == priority }
    }
    
    public func getTasksDueToday() -> [Task] {
        let calendar = Calendar.current
        return allTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: Date())
        }
    }
    
    public func getOverdueTasks() -> [Task] {
        return allTasks.filter { $0.isOverdue }
    }
}