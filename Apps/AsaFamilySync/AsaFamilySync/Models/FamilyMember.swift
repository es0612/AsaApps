import Foundation
#if FIREBASE_ENABLED
import FirebaseFirestoreSwift
#endif

enum MemberRole: String, Codable, CaseIterable {
    case owner = "owner"
    case admin = "admin"
    case member = "member"

    var displayName: String {
        switch self {
        case .owner: return "オーナー"
        case .admin: return "管理者"
        case .member: return "メンバー"
        }
    }

    var canManageMembers: Bool {
        self == .owner || self == .admin
    }

    var canDeleteEvents: Bool {
        self == .owner || self == .admin
    }
}

struct FamilyMember: Codable, Identifiable {
    #if FIREBASE_ENABLED
    @DocumentID var id: String?
    #else
    var id: String?
    #endif
    var userId: String
    var name: String
    var email: String
    var role: MemberRole
    var profileImageUrl: String?
    var joinedAt: Date
    var lastActiveAt: Date?
    var color: String // 表示用の色（16進数）

    init(userId: String, name: String, email: String, role: MemberRole = .member) {
        self.userId = userId
        self.name = name
        self.email = email
        self.role = role
        self.joinedAt = Date()
        self.color = Self.generateRandomColor()
    }

    static func generateRandomColor() -> String {
        let colors = [
            "#C68C53", // AsaCoffeeBrown
            "#8B5A2B", // AsaMocha
            "#7A918D", // AsaMutedSage
            "#FF6B6B", // Coral
            "#4ECDC4", // Turquoise
            "#45B7D1", // Sky Blue
            "#96CEB4", // Mint
            "#FECA57", // Yellow
            "#FF9FF3", // Pink
            "#54A0FF"  // Blue
        ]
        return colors.randomElement() ?? "#C68C53"
    }
}