//
//  Event.swift
//  AsaEventPlanner
//  
//  Created on 2025/08/03
//

import Foundation
import SwiftData

enum EventType: String, CaseIterable, Codable {
    case birthday = "誕生日"
    case meeting = "会議"
    case travel = "旅行"
    case party = "パーティー"
    case wedding = "結婚式"
    case conference = "カンファレンス"
    case workshop = "ワークショップ"
    case family = "家族行事"
    case other = "その他"
    
    var iconName: String {
        switch self {
        case .birthday: return "gift.fill"
        case .meeting: return "person.3.fill"
        case .travel: return "airplane"
        case .party: return "party.popper.fill"
        case .wedding: return "heart.fill"
        case .conference: return "mic.fill"
        case .workshop: return "hammer.fill"
        case .family: return "house.fill"
        case .other: return "calendar"
        }
    }
}

enum EventStatus: String, CaseIterable, Codable {
    case planning = "計画中"
    case inProgress = "準備中"
    case ready = "準備完了"
    case completed = "完了"
    case cancelled = "キャンセル"
}

@Model
final class Event {
    var id: UUID
    var title: String
    var eventDescription: String
    var eventDate: Date
    var location: String
    var eventType: EventType
    var status: EventStatus
    var budget: Double
    var actualSpent: Double
    var isAllDay: Bool
    var endDate: Date?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade) var tasks: [EventTask] = []
    @Relationship(deleteRule: .cascade) var participants: [Participant] = []
    @Relationship(deleteRule: .cascade) var shoppingItems: [ShoppingItem] = []
    
    init(
        title: String,
        eventDescription: String = "",
        eventDate: Date,
        location: String = "",
        eventType: EventType = .other,
        budget: Double = 0.0,
        isAllDay: Bool = true,
        endDate: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.eventDescription = eventDescription
        self.eventDate = eventDate
        self.location = location
        self.eventType = eventType
        self.status = .planning
        self.budget = budget
        self.actualSpent = 0.0
        self.isAllDay = isAllDay
        self.endDate = endDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var daysUntilEvent: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: eventDate).day ?? 0
    }
    
    var isUpcoming: Bool {
        eventDate > Date()
    }
    
    var completedTasksCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    var totalTasksCount: Int {
        tasks.count
    }
    
    var completionProgress: Double {
        guard totalTasksCount > 0 else { return 0.0 }
        return Double(completedTasksCount) / Double(totalTasksCount)
    }
    
    var budgetProgress: Double {
        guard budget > 0 else { return 0.0 }
        return min(actualSpent / budget, 1.0)
    }
}
