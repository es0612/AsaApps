import Foundation
import SwiftUI
import AsaUIKit

@MainActor
@Observable
public final class TaskColumnViewModel {
    
    // MARK: - Properties
    
    public let column: TaskColumn
    public private(set) var isDragOver = false
    
    // MARK: - Initialization
    
    public init(column: TaskColumn) {
        self.column = column
    }
    
    // MARK: - Computed Properties
    
    public var title: String {
        column.title
    }
    
    public var status: TaskStatus {
        column.status
    }
    
    public var taskCount: Int {
        column.taskCount
    }
    
    public var tasks: [Task] {
        column.tasks
    }
    
    public var columnColor: Color {
        switch status {
        case .todo:
            return AsaColors.todoColumn
        case .inProgress:
            return AsaColors.inProgressColumn
        case .done:
            return AsaColors.doneColumn
        }
    }
    
    public var headerColor: Color {
        switch status {
        case .todo:
            return AsaColors.mutedSage
        case .inProgress:
            return AsaColors.coffeeBrown
        case .done:
            return AsaColors.mocha
        }
    }
    
    // MARK: - Drag & Drop Methods
    
    public func setDragOver(_ isOver: Bool) {
        isDragOver = isOver
    }
    
    public func canAcceptDrop(task: Task) -> Bool {
        return task.status != status
    }
    
    // MARK: - Statistics
    
    public var highPriorityCount: Int {
        column.highPriorityTaskCount
    }
    
    public var overdueCount: Int {
        column.overdueTaskCount
    }
    
    public var hasHighPriorityTasks: Bool {
        highPriorityCount > 0
    }
    
    public var hasOverdueTasks: Bool {
        overdueCount > 0
    }
}