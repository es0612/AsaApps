import Foundation
#if FIREBASE_ENABLED
import FirebaseFirestoreSwift
#endif

struct FamilyGroup: Codable, Identifiable {
    #if FIREBASE_ENABLED
    @DocumentID var id: String?
    #else
    var id: String?
    #endif
    var name: String
    var description: String?
    var ownerId: String
    var createdAt: Date
    var updatedAt: Date
    var inviteCode: String
    var maxMembers: Int = 10

    init(name: String, description: String? = nil, ownerId: String) {
        self.name = name
        self.description = description
        self.ownerId = ownerId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.inviteCode = Self.generateInviteCode()
    }

    static func generateInviteCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).compactMap { _ in characters.randomElement() })
    }
}