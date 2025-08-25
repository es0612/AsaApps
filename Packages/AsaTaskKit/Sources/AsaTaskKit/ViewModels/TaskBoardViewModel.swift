import Foundation
import SwiftUI
import SwiftData
import AsaUIKit

@MainActor
@Observable
public final class TaskBoardViewModel {
    
    // MARK: - Properties
    
    private let dataService: TaskDataService
    public private(set) var currentBoard: TaskBoard?
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?
    
    // UI State
    public var showingAddTask = false
    public var showingTaskDetail = false
    public var selectedTask: Task?
    public var draggedTask: Task?
    
    // Task Form Properties
    public var newTaskTitle = ""
    public var newTaskDescription = ""
    public var newTaskPriority: AsaTaskPriority = .medium
    public var newTaskDueDate: Date?
    public var hasNewTaskDueDate = false
    
    // MARK: - Computed Properties
    
    public var todoTasks: [Task] {
        currentBoard?.getColumn(for: .todo)?.tasks ?? []
    }
    
    public var inProgressTasks: [Task] {
        currentBoard?.getColumn(for: .inProgress)?.tasks ?? []
    }
    
    public var doneTasks: [Task] {
        currentBoard?.getColumn(for: .done)?.tasks ?? []
    }
    
    public var overdueTasks: [Task] {
        currentBoard?.getOverdueTasks() ?? []
    }
    
    public var totalTaskCount: Int {
        currentBoard?.totalTaskCount ?? 0
    }
    
    public var completedTaskCount: Int {
        currentBoard?.completedTaskCount ?? 0
    }
    
    public var progressPercentage: Double {
        currentBoard?.progressPercentage ?? 0
    }
    
    // MARK: - Initialization
    
    public init(dataService: TaskDataService) {
        self.dataService = dataService
    }
    
    // MARK: - Board Management
    
    public func loadBoard() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let boards = try await dataService.fetchAllBoards()
            
            if let existingBoard = boards.first {
                currentBoard = existingBoard
            } else {
                // デフォルトボードを作成
                currentBoard = try await dataService.createBoard(
                    title: "マイタスクボード",
                    description: "デフォルトのタスク管理ボード"
                )
            }
        } catch {
            errorMessage = "ボードの読み込みに失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    public func createNewBoard(title: String, description: String? = nil) async {
        do {
            currentBoard = try await dataService.createBoard(title: title, description: description)
        } catch {
            errorMessage = "ボードの作成に失敗しました: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Task Management
    
    public func addNewTask() async {
        guard let board = currentBoard,
              !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        do {
            let dueDate = hasNewTaskDueDate ? newTaskDueDate : nil
            _ = try await dataService.createTask(
                title: newTaskTitle,
                description: newTaskDescription.isEmpty ? nil : newTaskDescription,
                priority: newTaskPriority,
                dueDate: dueDate,
                in: board,
                column: .todo
            )
            
            // フォームをリセット
            clearTaskForm()
            showingAddTask = false
        } catch {
            errorMessage = "タスクの作成に失敗しました: \(error.localizedDescription)"
        }
    }
    
    public func updateTask(
        _ task: Task,
        title: String? = nil,
        description: String? = nil,
        priority: AsaTaskPriority? = nil,
        dueDate: Date? = nil
    ) async {
        do {
            try await dataService.updateTask(
                task,
                title: title,
                description: description,
                priority: priority,
                dueDate: dueDate
            )
        } catch {
            errorMessage = "タスクの更新に失敗しました: \(error.localizedDescription)"
        }
    }
    
    public func deleteTask(_ task: Task) async {
        do {
            try await dataService.deleteTask(task)
        } catch {
            errorMessage = "タスクの削除に失敗しました: \(error.localizedDescription)"
        }
    }
    
    public func moveTask(_ task: Task, to status: TaskStatus) async {
        guard let board = currentBoard else { return }
        
        do {
            try await dataService.moveTask(task, to: status, in: board)
        } catch {
            errorMessage = "タスクの移動に失敗しました: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Drag & Drop Support
    
    public func startDragging(_ task: Task) {
        draggedTask = task
    }
    
    public func endDragging() {
        draggedTask = nil
    }
    
    public func canDrop(task: Task, to status: TaskStatus) -> Bool {
        return task.status != status
    }
    
    public func handleDrop(task: Task, to status: TaskStatus) async {
        await moveTask(task, to: status)
        endDragging()
    }
    
    // MARK: - Task Selection
    
    public func selectTask(_ task: Task) {
        selectedTask = task
        showingTaskDetail = true
    }
    
    public func deselectTask() {
        selectedTask = nil
        showingTaskDetail = false
    }
    
    // MARK: - Form Management
    
    public func prepareAddTask() {
        clearTaskForm()
        showingAddTask = true
    }
    
    private func clearTaskForm() {
        newTaskTitle = ""
        newTaskDescription = ""
        newTaskPriority = .medium
        newTaskDueDate = nil
        hasNewTaskDueDate = false
    }
    
    // MARK: - Error Handling
    
    public func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Statistics
    
    public func getTasksByPriority(_ priority: AsaTaskPriority) -> [Task] {
        return currentBoard?.getTasksByPriority(priority) ?? []
    }
    
    public func getTasksDueToday() -> [Task] {
        return currentBoard?.getTasksDueToday() ?? []
    }
}