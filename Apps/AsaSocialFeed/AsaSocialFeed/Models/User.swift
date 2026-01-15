import Foundation
#if FIREBASE_ENABLED
@preconcurrency import FirebaseFirestore
#endif

// MARK: - User Model

/// Firebase認証ユーザーのプロファイル
struct User: Codable, Identifiable, Sendable {
    #if FIREBASE_ENABLED
    @DocumentID var id: String?
    #else
    var id: String?
    #endif

    var email: String
    var displayName: String
    var photoURL: String?
    var fcmToken: String?
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Computed Properties

    /// FirebaseのUID
    var uid: String {
        id ?? ""
    }

    /// 表示名（名前がなければメールのローカル部分）
    var displayNameOrEmail: String {
        displayName.isEmpty ? email.components(separatedBy: "@").first ?? email : displayName
    }

    // MARK: - Initializer

    init(
        id: String? = nil,
        email: String,
        displayName: String,
        photoURL: String? = nil,
        fcmToken: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.fcmToken = fcmToken
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - User Extension for Equatable

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - User Extension for Hashable

extension User: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
