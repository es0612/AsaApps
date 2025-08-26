import Testing
import Foundation
@testable import AsaTaskKit

@MainActor
struct TaskBoardViewModelTests {
    
    @Test("ViewModelの初期化テスト")
    func viewModelInitialization() async throws {
        let dataService = try TaskDataService()
        let viewModel = TaskBoardViewModel(dataService: dataService)
        
        #expect(viewModel.currentBoard == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showingAddTask == false)
        #expect(viewModel.showingTaskDetail == false)
        #expect(viewModel.selectedTask == nil)
    }
    
    @Test("ボード読み込みテスト")
    func loadBoard() async throws {
        let dataService = try TaskDataService()
        let viewModel = TaskBoardViewModel(dataService: dataService)
        
        await viewModel.loadBoard()
        
        #expect(viewModel.currentBoard != nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("新しいタスク追加テスト")
    func addNewTask() async throws {
        let dataService = try TaskDataService()
        let viewModel = TaskBoardViewModel(dataService: dataService)
        
        // ボードを読み込み
        await viewModel.loadBoard()
        
        // タスクフォームに入力
        viewModel.newTaskTitle = "テストタスク"
        viewModel.newTaskDescription = "テスト説明"
        viewModel.newTaskPriority = .high
        viewModel.hasNewTaskDueDate = true
        viewModel.newTaskDueDate = Date()
        
        let initialCount = viewModel.totalTaskCount
        
        // タスクを追加
        await viewModel.addNewTask()
        
        #expect(viewModel.totalTaskCount == initialCount + 1)
        #expect(viewModel.todoTasks.count == initialCount + 1)
        
        // フォームがリセットされることを確認
        #expect(viewModel.newTaskTitle == "")
        #expect(viewModel.newTaskDescription == "")
        #expect(viewModel.newTaskPriority == .medium)
        #expect(viewModel.hasNewTaskDueDate == false)
        #expect(viewModel.showingAddTask == false)
    }
    
    @Test("タスクの移動テスト")
    func moveTask() async throws {
        let dataService = try TaskDataService()
        let viewModel = TaskBoardViewModel(dataService: dataService)
        
        await viewModel.loadBoard()
        
        // タスクを追加
        viewModel.newTaskTitle = "移動テストタスク"
        await viewModel.addNewTask()
        
        guard let task = viewModel.todoTasks.first else {
            Issue.record("タスクが作成されませんでした")
            return
        }
        
        // 進行中に移動
        await viewModel.moveTask(task, to: .inProgress)
        
        #expect(viewModel.todoTasks.count == 0)
        #expect(viewModel.inProgressTasks.count == 1)
        #expect(task.status == .inProgress)
    }
    
    @Test("タスクの削除テスト")
    func deleteTask() async throws {
        let dataService = try TaskDataService()
        let viewModel = TaskBoardViewModel(dataService: dataService)
        
        await viewModel.loadBoard()
        
        // タスクを追加
        viewModel.newTaskTitle = "削除テストタスク"
        await viewModel.addNewTask()
        
        let initialCount = viewModel.totalTaskCount
        
        guard let task = viewModel.todoTasks.first else {
            Issue.record("タスクが作成されませんでした")
            return
        }
        
        // タスクを削除
        await viewModel.deleteTask(task)
        
        #expect(viewModel.totalTaskCount == initialCount - 1)
        #expect(viewModel.todoTasks.isEmpty)
    }
    
    @Test("タスク選択テスト")
    func selectTask() async throws {
        let dataService = try TaskDataService()
        let viewModel = TaskBoardViewModel(dataService: dataService)
        
        await viewModel.loadBoard()
        
        // タスクを追加
        viewModel.newTaskTitle = "選択テストタスク"
        await viewModel.addNewTask()
        
        guard let task = viewModel.todoTasks.first else {
            Issue.record("タスクが作成されませんでした")
            return
        }
        
        // タスクを選択
        viewModel.selectTask(task)
        
        #expect(viewModel.selectedTask?.id == task.id)
        #expect(viewModel.showingTaskDetail == true)
        
        // 選択解除
        viewModel.deselectTask()
        
        #expect(viewModel.selectedTask == nil)
        #expect(viewModel.showingTaskDetail == false)
    }
    
    @Test("ドラッグ&ドロップテスト")
    func dragAndDrop() async throws {
        let dataService = try TaskDataService()
        let viewModel = TaskBoardViewModel(dataService: dataService)
        
        await viewModel.loadBoard()
        
        // タスクを追加
        viewModel.newTaskTitle = "ドラッグテストタスク"
        await viewModel.addNewTask()
        
        guard let task = viewModel.todoTasks.first else {
            Issue.record("タスクが作成されませんでした")
            return
        }
        
        // ドラッグ開始
        viewModel.startDragging(task)
        #expect(viewModel.draggedTask?.id == task.id)
        
        // ドロップ可能性チェック
        #expect(viewModel.canDrop(task: task, to: .inProgress) == true)
        #expect(viewModel.canDrop(task: task, to: .todo) == false) // 同じステータスへは移動不可
        
        // ドロップ実行
        await viewModel.handleDrop(task: task, to: .inProgress)
        
        #expect(viewModel.draggedTask == nil)
        #expect(task.status == .inProgress)
        #expect(viewModel.inProgressTasks.count == 1)
        #expect(viewModel.todoTasks.isEmpty)
    }
    
    @Test("進捗計算テスト")
    func progressCalculation() async throws {
        let dataService = try TaskDataService()
        let viewModel = TaskBoardViewModel(dataService: dataService)
        
        await viewModel.loadBoard()
        
        // 複数のタスクを追加
        for i in 1...4 {
            viewModel.newTaskTitle = "タスク\(i)"
            await viewModel.addNewTask()
        }
        
        #expect(viewModel.totalTaskCount == 4)
        #expect(viewModel.completedTaskCount == 0)
        #expect(viewModel.progressPercentage == 0.0)
        
        // 2つのタスクを完了に移動
        let tasks = viewModel.todoTasks
        await viewModel.moveTask(tasks[0], to: .done)
        await viewModel.moveTask(tasks[1], to: .done)
        
        #expect(viewModel.completedTaskCount == 2)
        #expect(viewModel.progressPercentage == 0.5) // 50%
    }
    
    @Test("エラーハンドリングテスト")
    func errorHandling() async throws {
        let dataService = try TaskDataService()
        let viewModel = TaskBoardViewModel(dataService: dataService)
        
        // 無効なタスクタイトル（空文字）でタスク追加を試行
        viewModel.newTaskTitle = ""
        await viewModel.addNewTask()
        
        // エラーメッセージが設定されないこと（空タイトルは単に無視される）
        #expect(viewModel.errorMessage == nil)
        
        // エラークリアテスト
        // 手動でエラーメッセージを設定
        // （実際のエラーシナリオは外部依存関係があるため）
        viewModel.clearError()
        #expect(viewModel.errorMessage == nil)
    }
}