//
//  Reminder.swift
//  AsaReminder
//  
//  Created on 2025/07/19
//

import Foundation
import SwiftData

@Model
final class Reminder {
    var id: UUID
    var title: String
    var content: String
    var scheduledDate: Date
    var isCompleted: Bool
    var hasNotification: Bool
    var notificationIdentifier: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        title: String,
        content: String = "",
        scheduledDate: Date,
        hasNotification: Bool = true
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.scheduledDate = scheduledDate
        self.isCompleted = false
        self.hasNotification = hasNotification
        self.notificationIdentifier = hasNotification ? UUID().uuidString : nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var isOverdue: Bool {
        return !isCompleted && scheduledDate < Date()
    }
    
    var timeUntilDue: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: scheduledDate, relativeTo: Date())
    }
}
