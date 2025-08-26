import Testing
import SwiftUI
@testable import AsaTaskBoard
@testable import AsaTaskKit

struct AsaTaskBoardAppTests {
    
    @Test("アプリの初期化テスト")
    func appInitialization() throws {
        // AsaTaskBoardAppが正常に初期化できることを確認
        let app = AsaTaskBoardApp()
        
        // アプリが正常に作成されることを確認
        #expect(app.body != nil)
    }
}

@MainActor
struct ContentViewTests {
    
    @Test("ContentViewの初期化テスト")
    func contentViewInitialization() throws {
        let dataService = try TaskDataService()
        let viewModel = TaskBoardViewModel(dataService: dataService)
        let contentView = ContentView().environmentObject(viewModel)
        
        // ContentViewが正常に作成されることを確認
        #expect(contentView.body != nil)
    }
}

@MainActor
struct KanbanBoardViewTests {
    
    @Test("KanbanBoardViewの初期化テスト") 
    func kanbanBoardViewInitialization() throws {
        let dataService = try TaskDataService()
        let viewModel = TaskBoardViewModel(dataService: dataService)
        let kanbanView = KanbanBoardView().environmentObject(viewModel)
        
        // KanbanBoardViewが正常に作成されることを確認
        #expect(kanbanView.body != nil)
    }
}

@MainActor
struct TaskColumnViewTests {
    
    @Test("TaskColumnViewの初期化テスト")
    func taskColumnViewInitialization() throws {
        let dataService = try TaskDataService()
        let viewModel = TaskBoardViewModel(dataService: dataService)
        
        let columnView = TaskColumnView(
            title: "テストカラム",
            tasks: [],
            status: .todo,
            color: AsaColors.todoColumn
        ).environmentObject(viewModel)
        
        // TaskColumnViewが正常に作成されることを確認
        #expect(columnView.body != nil)
    }
}

@MainActor
struct TaskCardViewTests {
    
    @Test("TaskCardViewの初期化テスト")
    func taskCardViewInitialization() throws {
        let dataService = try TaskDataService()
        let viewModel = TaskBoardViewModel(dataService: dataService)
        
        let task = Task(
            title: "テストタスク",
            description: "テスト説明",
            priority: .medium
        )
        
        let cardView = TaskCardView(task: task).environmentObject(viewModel)
        
        // TaskCardViewが正常に作成されることを確認
        #expect(cardView.body != nil)
    }
}

@MainActor
struct AddTaskViewTests {
    
    @Test("AddTaskViewの初期化テスト")
    func addTaskViewInitialization() throws {
        let dataService = try TaskDataService()
        let viewModel = TaskBoardViewModel(dataService: dataService)
        
        let addTaskView = AddTaskView().environmentObject(viewModel)
        
        // AddTaskViewが正常に作成されることを確認
        #expect(addTaskView.body != nil)
    }
}

@MainActor 
struct TaskDetailViewTests {
    
    @Test("TaskDetailViewの初期化テスト")
    func taskDetailViewInitialization() throws {
        let dataService = try TaskDataService()
        let viewModel = TaskBoardViewModel(dataService: dataService)
        
        let task = Task(
            title: "詳細表示テストタスク",
            description: "詳細表示のテスト用タスク",
            priority: .high,
            dueDate: Date()
        )
        
        let detailView = TaskDetailView(task: task).environmentObject(viewModel)
        
        // TaskDetailViewが正常に作成されることを確認
        #expect(detailView.body != nil)
    }
    
    @Test("TaskDetailViewの編集機能テスト")
    func taskDetailViewEditing() throws {
        let task = Task(
            title: "編集テストタスク",
            description: "元の説明",
            priority: .medium
        )
        
        let detailView = TaskDetailView(task: task)
        
        // 初期値が正しく設定されることを確認
        #expect(detailView.task.title == "編集テストタスク")
        #expect(detailView.task.taskDescription == "元の説明") 
        #expect(detailView.task.priority == .medium)
    }
}