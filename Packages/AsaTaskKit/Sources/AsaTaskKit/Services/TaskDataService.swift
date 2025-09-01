import Foundation
import SwiftData
import AsaUIKit

/// タスクデータの永続化を管理するサービスクラス
@MainActor
public final class TaskDataService {
    private let container: ModelContainer
    
    public init() throws {
        let schema = Schema([
            Task.self,
            TaskColumn.self,
            TaskBoard.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        self.container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
    
    // MARK: - Container Access
    
    public var modelContext: ModelContext {
        container.mainContext
    }
    
    // MARK: - TaskBoard Operations
    
    public func createBoard(title: String, description: String? = nil) throws -> TaskBoard {
        let context = modelContext
        let board = TaskBoard(title: title, description: description)
        context.insert(board)
        try context.save()
        return board
    }
    
    public func fetchAllBoards() throws -> [TaskBoard] {
        let context = modelContext
        let descriptor = FetchDescriptor<TaskBoard>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    public func fetchBoard(by id: UUID) throws -> TaskBoard? {
        let context = modelContext
        let descriptor = FetchDescriptor<TaskBoard>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
    
    public func deleteBoard(_ board: TaskBoard) throws {
        let context = modelContext
        context.delete(board)
        try context.save()
    }
    
    // MARK: - Task Operations
    
    public func createTask(
        title: String,
        description: String? = nil,
        priority: AsaTaskPriority = .medium,
        dueDate: Date? = nil,
        in board: TaskBoard,
        column: TaskStatus = .todo
    ) throws -> Task {
        let context = modelContext
        let task = Task(
            title: title,
            description: description,
            priority: priority,
            status: column,
            dueDate: dueDate
        )
        
        board.addTask(task, to: column)
        context.insert(task)
        try context.save()
        return task
    }
    
    public func updateTask(
        _ task: Task,
        title: String? = nil,
        description: String? = nil,
        priority: AsaTaskPriority? = nil,
        dueDate: Date? = nil
    ) throws {
        let context = modelContext
        task.updateDetails(
            title: title,
            description: description,
            priority: priority,
            dueDate: dueDate
        )
        try context.save()
    }
    
    public func moveTask(
        _ task: Task,
        to columnStatus: TaskStatus,
        in board: TaskBoard
    ) throws {
        let context = modelContext
        board.moveTask(task, to: columnStatus)
        try context.save()
    }
    
    public func deleteTask(_ task: Task) throws {
        let context = modelContext
        task.column?.removeTask(task)
        context.delete(task)
        try context.save()
    }
    
    // MARK: - Query Methods
    
    public func fetchTasks(
        for board: TaskBoard,
        status: TaskStatus? = nil,
        priority: AsaTaskPriority? = nil
    ) throws -> [Task] {
        var tasks = board.allTasks
        if let status = status {
            tasks = tasks.filter { $0.status == status }
        }
        if let priority = priority {
            tasks = tasks.filter { $0.priority == priority }
        }
        return tasks.sorted { lhs, rhs in
            if lhs.priority != rhs.priority {
                return lhs.priority.rawValue < rhs.priority.rawValue
            }
            return lhs.createdAt > rhs.createdAt
        }
    }
    
    public func fetchOverdueTasks() throws -> [Task] {
        let context = modelContext
        let all = try context.fetch(FetchDescriptor<Task>())
        return all.filter { $0.isOverdue }.sorted { (a, b) in
            (a.dueDate ?? .distantFuture) < (b.dueDate ?? .distantFuture)
        }
    }
    
    public func fetchTasksDueToday() throws -> [Task] {
        let context = modelContext
        let all = try context.fetch(FetchDescriptor<Task>())
        let calendar = Calendar.current
        return all.filter { task in
            if let due = task.dueDate {
                return calendar.isDate(due, inSameDayAs: Date())
            }
            return false
        }.sorted { (a, b) in
            (a.dueDate ?? .distantFuture) < (b.dueDate ?? .distantFuture)
        }
    }
    
    // MARK: - Utility Methods
    
    public func save() throws {
        try modelContext.save()
    }
}

// MARK: - Preview Support

#if DEBUG
public extension TaskDataService {
    static func previewService() throws -> TaskDataService {
        let schema = Schema([
            Task.self,
            TaskColumn.self,
            TaskBoard.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        
        let service = try TaskDataService()

        // プレビュー用のサンプルデータを作成（同期）
        let board = try service.createBoard(
            title: "サンプルプロジェクト",
            description: "プレビュー用のサンプルタスクボード"
        )

        _ = try service.createTask(
            title: "API設計",
            description: "RESTful APIの設計と仕様書作成",
            priority: .high,
            dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
            in: board,
            column: .todo
        )

        _ = try service.createTask(
            title: "UI実装",
            description: "メイン画面のUI実装",
            priority: .medium,
            in: board,
            column: .inProgress
        )

        _ = try service.createTask(
            title: "単体テスト",
            description: "ユニットテストの作成",
            priority: .low,
            in: board,
            column: .done
        )

        return service
    }
}
#endif
