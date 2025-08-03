//
//  EventTask.swift
//  AsaEventPlanner
//  
//  Created on 2025/08/03
//

import Foundation
import SwiftData

enum TaskPriority: String, CaseIterable, Codable {
    case low = "低"
    case medium = "中"
    case high = "高"
    case urgent = "緊急"
    
    var color: String {
        switch self {
        case .low: return "AsaMutedSage"
        case .medium: return "AsaCoffeeBrown"
        case .high: return "AsaMocha"
        case .urgent: return "red"
        }
    }
    
    var iconName: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "arrow.up.circle"
        case .urgent: return "exclamationmark.circle.fill"
        }
    }
}

@Model
final class EventTask {
    var id: UUID
    var title: String
    var taskDescription: String
    var isCompleted: Bool
    var priority: TaskPriority
    var dueDate: Date?
    var completedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(inverse: \Event.tasks) var event: Event?
    
    init(
        title: String,
        taskDescription: String = "",
        priority: TaskPriority = .medium,
        dueDate: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = taskDescription
        self.isCompleted = false
        self.priority = priority
        self.dueDate = dueDate
        self.completedAt = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }
    
    var timeUntilDue: String? {
        guard let dueDate = dueDate else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: dueDate, relativeTo: Date())
    }
    
    func toggleCompletion() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
        updatedAt = Date()
    }
}