import Foundation
import SwiftData
import AsaUIKit

@Model
public final class Task {
    public var id: UUID
    public var title: String
    public var taskDescription: String?
    public var priorityRawValue: String
    public var statusRawValue: String
    public var dueDate: Date?
    public var createdAt: Date
    public var updatedAt: Date
    
    // Computed properties for enum access
    public var priority: AsaTaskPriority {
        get { AsaTaskPriority(rawValue: priorityRawValue) ?? .medium }
        set { priorityRawValue = newValue.rawValue }
    }
    
    public var status: TaskStatus {
        get { TaskStatus(rawValue: statusRawValue) ?? .todo }
        set { statusRawValue = newValue.rawValue }
    }
    
    // リレーション
    public var column: TaskColumn?
    
    public init(
        title: String,
        description: String? = nil,
        priority: AsaTaskPriority = .medium,
        status: TaskStatus = .todo,
        dueDate: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = description
        self.priorityRawValue = priority.rawValue
        self.statusRawValue = status.rawValue
        self.dueDate = dueDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Methods
    
    public func updateStatus(_ newStatus: TaskStatus) {
        self.status = newStatus
        updatedAt = Date()
    }
    
    public func updateDetails(
        title: String? = nil,
        description: String? = nil,
        priority: AsaTaskPriority? = nil,
        dueDate: Date? = nil
    ) {
        if let title = title {
            self.title = title
        }
        if let description = description {
            self.taskDescription = description
        }
        if let priority = priority {
            self.priority = priority
        }
        if let dueDate = dueDate {
            self.dueDate = dueDate
        }
        self.updatedAt = Date()
    }
    
    public var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date() && status != .done
    }
}

// MARK: - TaskStatus
public enum TaskStatus: String, CaseIterable, Codable, Identifiable {
    case todo = "todo"
    case inProgress = "inProgress"
    case done = "done"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .todo: return "To Do"
        case .inProgress: return "進行中"
        case .done: return "完了"
        }
    }
    
    public var systemImageName: String {
        switch self {
        case .todo: return "circle"
        case .inProgress: return "arrow.clockwise"
        case .done: return "checkmark.circle.fill"
        }
    }
}