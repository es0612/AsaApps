//
//  FamilyMember.swift
//  AsaFamilyBudget
//
//  Created by Asa Apps on 2025.
//

import Foundation
import SwiftData

enum MemberRole: String, Codable, CaseIterable {
    case parent = "親"
    case child = "子供"
    case viewer = "閲覧者"

    var canEdit: Bool {
        switch self {
        case .parent: return true
        case .child: return false
        case .viewer: return false
        }
    }

    var canAddTransaction: Bool {
        switch self {
        case .parent, .child: return true
        case .viewer: return false
        }
    }
}

@Model
final class FamilyMember {
    // MARK: - Properties
    var id: UUID
    var name: String
    var email: String?
    var avatarName: String
    var roleRawValue: String
    var colorHex: String
    var isActive: Bool
    var joinedAt: Date
    var lastActiveAt: Date?

    // MARK: - Relationships
    var transactions: [Transaction]?

    // MARK: - Computed Properties
    var role: MemberRole {
        get { MemberRole(rawValue: roleRawValue) ?? .viewer }
        set { roleRawValue = newValue.rawValue }
    }

    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first ?? Character(" ")
        let lastInitial = components.count > 1 ? components.last?.first ?? Character(" ") : Character(" ")
        return "\(firstInitial)\(lastInitial)".uppercased()
    }

    // MARK: - Initialization
    init(
        name: String,
        email: String? = nil,
        avatarName: String = "person.circle.fill",
        role: MemberRole = .viewer,
        colorHex: String = "#C68C53",
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.avatarName = avatarName
        self.roleRawValue = role.rawValue
        self.colorHex = colorHex
        self.isActive = isActive
        self.joinedAt = Date()
        self.lastActiveAt = nil
    }

    // MARK: - Methods
    func updateLastActive() {
        lastActiveAt = Date()
    }

    func updateRole(_ newRole: MemberRole) {
        self.role = newRole
    }

    // MARK: - Static Methods
    static func sampleMembers() -> [FamilyMember] {
        return [
            FamilyMember(name: "パパ", avatarName: "person.fill", role: .parent, colorHex: "#C68C53"),
            FamilyMember(name: "ママ", avatarName: "person.fill", role: .parent, colorHex: "#E8D5B9"),
            FamilyMember(name: "太郎", avatarName: "face.smiling.fill", role: .child, colorHex: "#7A918D"),
            FamilyMember(name: "花子", avatarName: "face.smiling.fill", role: .child, colorHex: "#8B5A2B")
        ]
    }
}