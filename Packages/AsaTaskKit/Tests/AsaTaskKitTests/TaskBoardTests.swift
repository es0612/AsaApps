import Testing
import Foundation
@testable import AsaTaskKit

struct TaskColumnTests {
    
    @Test("TaskColumnの初期化テスト")
    func taskColumnInitialization() throws {
        let title = "テストカラム"
        let status = TaskStatus.todo
        let position = 0
        
        let column = TaskColumn(
            title: title,
            status: status,
            position: position
        )
        
        #expect(column.title == title)
        #expect(column.status == status)
        #expect(column.position == position)
        #expect(column.tasks.isEmpty)
        #expect(column.id != UUID())
    }
    
    @Test("TaskColumnにタスク追加テスト")
    func addTaskToColumn() throws {
        let column = TaskColumn(title: "ToDo", status: .todo, position: 0)
        let task = Task(title: "テストタスク")
        
        column.addTask(task)
        
        #expect(column.tasks.count == 1)
        #expect(column.tasks.first?.id == task.id)
        #expect(task.column?.id == column.id)
        #expect(task.status == .todo)
    }
    
    @Test("TaskColumnからタスク削除テスト")
    func removeTaskFromColumn() throws {
        let column = TaskColumn(title: "ToDo", status: .todo, position: 0)
        let task = Task(title: "テストタスク")
        
        column.addTask(task)
        #expect(column.tasks.count == 1)
        
        column.removeTask(task)
        #expect(column.tasks.isEmpty)
        #expect(task.column == nil)
    }
    
    @Test("タスクのカラム間移動テスト")
    func moveTaskBetweenColumns() throws {
        let todoColumn = TaskColumn(title: "ToDo", status: .todo, position: 0)
        let inProgressColumn = TaskColumn(title: "進行中", status: .inProgress, position: 1)
        let task = Task(title: "移動タスク")
        
        // 最初にToDoカラムに追加
        todoColumn.addTask(task)
        #expect(todoColumn.tasks.count == 1)
        #expect(inProgressColumn.tasks.count == 0)
        #expect(task.status == .todo)
        
        // 進行中カラムに移動
        todoColumn.moveTask(task, to: inProgressColumn)
        #expect(todoColumn.tasks.count == 0)
        #expect(inProgressColumn.tasks.count == 1)
        #expect(task.status == .inProgress)
        #expect(task.column?.id == inProgressColumn.id)
    }
    
    @Test("カラムの統計メソッドテスト")
    func columnStatistics() throws {
        let column = TaskColumn(title: "テスト", status: .todo, position: 0)
        
        // 様々な優先度と期限のタスクを作成
        let highPriorityTask = Task(title: "高優先度", priority: .high)
        let mediumPriorityTask = Task(title: "中優先度", priority: .medium)
        let overdueTask = Task(
            title: "期限切れ",
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        )
        let completedTask = Task(title: "完了タスク", status: .done)
        
        column.addTask(highPriorityTask)
        column.addTask(mediumPriorityTask)
        column.addTask(overdueTask)
        column.addTask(completedTask)
        
        #expect(column.taskCount == 4)
        #expect(column.highPriorityTaskCount == 1)
        #expect(column.overdueTaskCount == 1)
        #expect(column.completedTaskCount == 1)
    }
}

struct TaskBoardTests {
    
    @Test("TaskBoardの初期化とデフォルトカラム作成テスト")
    func taskBoardInitialization() throws {
        let title = "テストボード"
        let description = "テスト用のボード"
        
        let board = TaskBoard(title: title, description: description)
        
        #expect(board.title == title)
        #expect(board.boardDescription == description)
        #expect(board.columns.count == 3)
        
        // デフォルトカラムの確認
        let todoColumn = board.getColumn(for: .todo)
        let inProgressColumn = board.getColumn(for: .inProgress)
        let doneColumn = board.getColumn(for: .done)
        
        #expect(todoColumn != nil)
        #expect(inProgressColumn != nil)
        #expect(doneColumn != nil)
        
        #expect(todoColumn?.title == "To Do")
        #expect(inProgressColumn?.title == "進行中")
        #expect(doneColumn?.title == "完了")
    }
    
    @Test("ボードにタスク追加テスト")
    func addTaskToBoard() throws {
        let board = TaskBoard(title: "テストボード")
        let task = Task(title: "新しいタスク")
        
        board.addTask(task, to: .todo)
        
        #expect(board.totalTaskCount == 1)
        #expect(board.getColumn(for: .todo)?.tasks.count == 1)
        #expect(task.status == .todo)
    }
    
    @Test("ボード内でのタスク移動テスト")
    func moveTaskInBoard() throws {
        let board = TaskBoard(title: "テストボード")
        let task = Task(title: "移動タスク")
        
        // ToDoに追加
        board.addTask(task, to: .todo)
        #expect(task.status == .todo)
        
        // 進行中に移動
        board.moveTask(task, to: .inProgress)
        #expect(task.status == .inProgress)
        #expect(board.getColumn(for: .todo)?.tasks.count == 0)
        #expect(board.getColumn(for: .inProgress)?.tasks.count == 1)
        
        // 完了に移動
        board.moveTask(task, to: .done)
        #expect(task.status == .done)
        #expect(board.getColumn(for: .inProgress)?.tasks.count == 0)
        #expect(board.getColumn(for: .done)?.tasks.count == 1)
    }
    
    @Test("ボードの進捗計算テスト")
    func boardProgressCalculation() throws {
        let board = TaskBoard(title: "進捗テストボード")
        
        // 複数のタスクを作成
        let task1 = Task(title: "タスク1")
        let task2 = Task(title: "タスク2")
        let task3 = Task(title: "タスク3")
        let task4 = Task(title: "タスク4")
        
        board.addTask(task1, to: .todo)
        board.addTask(task2, to: .inProgress)
        board.addTask(task3, to: .done)
        board.addTask(task4, to: .done)
        
        #expect(board.totalTaskCount == 4)
        #expect(board.completedTaskCount == 2)
        #expect(board.progressPercentage == 0.5) // 50%
    }
    
    @Test("ボードの統計メソッドテスト")
    func boardStatistics() throws {
        let board = TaskBoard(title: "統計テストボード")
        
        // 今日の日付
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        let highPriorityTask = Task(title: "高優先度", priority: .high)
        let todayDueTask = Task(title: "今日期限", dueDate: today)
        let overdueTask = Task(title: "期限切れ", dueDate: yesterday)
        
        board.addTask(highPriorityTask, to: .todo)
        board.addTask(todayDueTask, to: .inProgress)
        board.addTask(overdueTask, to: .todo)
        
        #expect(board.getTasksByPriority(.high).count == 1)
        #expect(board.getTasksDueToday().count == 1)
        #expect(board.getOverdueTasks().count == 1)
        #expect(board.overdueTaskCount == 1)
    }
    
    @Test("ボードからタスク削除テスト")
    func deleteTaskFromBoard() throws {
        let board = TaskBoard(title: "削除テストボード")
        let task = Task(title: "削除対象タスク")
        
        board.addTask(task, to: .todo)
        #expect(board.totalTaskCount == 1)
        
        board.deleteTask(task)
        #expect(board.totalTaskCount == 0)
        #expect(board.getColumn(for: .todo)?.tasks.count == 0)
    }
}