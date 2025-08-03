//
//  Participant.swift
//  AsaEventPlanner
//  
//  Created on 2025/08/03
//

import Foundation
import SwiftData

enum ParticipantStatus: String, CaseIterable, Codable {
    case invited = "招待済み"
    case confirmed = "参加確定"
    case declined = "欠席"
    case pending = "返答待ち"
    case maybe = "未定"
    
    var color: String {
        switch self {
        case .invited: return "AsaMutedSage"
        case .confirmed: return "green"
        case .declined: return "red"
        case .pending: return "orange"
        case .maybe: return "AsaCoffeeBrown"
        }
    }
    
    var iconName: String {
        switch self {
        case .invited: return "envelope.fill"
        case .confirmed: return "checkmark.circle.fill"
        case .declined: return "xmark.circle.fill"
        case .pending: return "clock.fill"
        case .maybe: return "questionmark.circle.fill"
        }
    }
}

@Model
final class Participant {
    var id: UUID
    var name: String
    var email: String
    var phone: String
    var role: String
    var status: ParticipantStatus
    var notes: String
    var invitedAt: Date
    var respondedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(inverse: \Event.participants) var event: Event?
    
    init(
        name: String,
        email: String = "",
        phone: String = "",
        role: String = "ゲスト",
        status: ParticipantStatus = .invited
    ) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.phone = phone
        self.role = role
        self.status = status
        self.notes = ""
        self.invitedAt = Date()
        self.respondedAt = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateStatus(_ newStatus: ParticipantStatus) {
        self.status = newStatus
        self.respondedAt = Date()
        self.updatedAt = Date()
    }
    
    var displayInfo: String {
        var info = name
        if !role.isEmpty && role != "ゲスト" {
            info += " (\(role))"
        }
        return info
    }
    
    var hasContactInfo: Bool {
        !email.isEmpty || !phone.isEmpty
    }
}