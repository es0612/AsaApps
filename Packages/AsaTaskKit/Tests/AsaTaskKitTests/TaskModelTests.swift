import Testing
import Foundation
@testable import AsaTaskKit

struct TaskModelTests {
    
    @Test("Taskの初期化テスト")
    func taskInitialization() throws {
        let title = "テストタスク"
        let description = "テスト用の説明"
        let priority = TaskPriority.high
        let dueDate = Date()
        
        let task = Task(
            title: title,
            description: description,
            priority: priority,
            status: .todo,
            dueDate: dueDate
        )
        
        #expect(task.title == title)
        #expect(task.taskDescription == description)
        #expect(task.priority == priority)
        #expect(task.status == .todo)
        #expect(task.dueDate == dueDate)
        #expect(task.id != UUID())
        #expect(task.createdAt != nil)
        #expect(task.updatedAt != nil)
    }
    
    @Test("Taskのデフォルト値テスト")
    func taskDefaultValues() throws {
        let task = Task(title: "デフォルトタスク")
        
        #expect(task.title == "デフォルトタスク")
        #expect(task.taskDescription == nil)
        #expect(task.priority == .medium)
        #expect(task.status == .todo)
        #expect(task.dueDate == nil)
    }
    
    @Test("Taskのステータス更新テスト")
    func taskStatusUpdate() throws {
        let task = Task(title: "ステータステスト")
        let originalUpdatedAt = task.updatedAt
        
        // 少し待ってからステータス更新
        Thread.sleep(forTimeInterval: 0.01)
        task.updateStatus(.inProgress)
        
        #expect(task.status == .inProgress)
        #expect(task.updatedAt > originalUpdatedAt)
    }
    
    @Test("Taskの詳細更新テスト")
    func taskDetailsUpdate() throws {
        let task = Task(title: "詳細テスト")
        let originalUpdatedAt = task.updatedAt
        
        Thread.sleep(forTimeInterval: 0.01)
        task.updateDetails(
            title: "更新されたタイトル",
            description: "更新された説明",
            priority: .high,
            dueDate: Date()
        )
        
        #expect(task.title == "更新されたタイトル")
        #expect(task.taskDescription == "更新された説明")
        #expect(task.priority == .high)
        #expect(task.dueDate != nil)
        #expect(task.updatedAt > originalUpdatedAt)
    }
    
    @Test("Taskの期限切れ判定テスト")
    func taskOverdueCheck() throws {
        // 期限切れのタスク
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let overdueTask = Task(
            title: "期限切れタスク",
            dueDate: pastDate
        )
        #expect(overdueTask.isOverdue == true)
        
        // 期限内のタスク
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let futureTask = Task(
            title: "期限内タスク",
            dueDate: futureDate
        )
        #expect(futureTask.isOverdue == false)
        
        // 完了したタスクは期限切れではない
        let completedTask = Task(
            title: "完了タスク",
            status: .done,
            dueDate: pastDate
        )
        #expect(completedTask.isOverdue == false)
        
        // 期日未設定のタスク
        let noDueDateTask = Task(title: "期日なしタスク")
        #expect(noDueDateTask.isOverdue == false)
    }
}

struct TaskStatusTests {
    
    @Test("TaskStatusの表示名テスト")
    func taskStatusDisplayNames() throws {
        #expect(TaskStatus.todo.displayName == "To Do")
        #expect(TaskStatus.inProgress.displayName == "進行中")
        #expect(TaskStatus.done.displayName == "完了")
    }
    
    @Test("TaskStatusのシステムアイコンテスト")
    func taskStatusSystemImages() throws {
        #expect(TaskStatus.todo.systemImageName == "circle")
        #expect(TaskStatus.inProgress.systemImageName == "arrow.clockwise")
        #expect(TaskStatus.done.systemImageName == "checkmark.circle.fill")
    }
    
    @Test("TaskStatusのCaseIterable適合テスト")
    func taskStatusAllCases() throws {
        let allCases = TaskStatus.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.todo))
        #expect(allCases.contains(.inProgress))
        #expect(allCases.contains(.done))
    }
}