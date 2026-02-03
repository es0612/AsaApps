//
//  LocalMember.swift
//  AsaCrowdsource
//
//  メンバーのデータモデル（ローカル用）
//

import Foundation
import SwiftData

/// メンバーのロール
enum MemberRole: String, Codable, CaseIterable, Sendable {
    case owner = "owner"
    case member = "member"

    var displayName: String {
        switch self {
        case .owner: return "オーナー"
        case .member: return "メンバー"
        }
    }

    var emoji: String {
        switch self {
        case .owner: return "👑"
        case .member: return "👤"
        }
    }
}

/// メンバーモデル（SwiftData用）
@Model
final class LocalMember {
    // MARK: - Properties

    /// 一意のID
    @Attribute(.unique) var id: UUID

    /// ユーザーID
    var userId: String

    /// 表示名
    var displayName: String

    /// メールアドレス
    var email: String

    /// 所属グループID
    var groupId: UUID

    /// ロール（rawValue保存）
    var roleRawValue: String

    /// 参加日時
    var joinedAt: Date

    /// 最終アクティブ日時
    var lastActiveAt: Date

    /// Firebase連携用ID
    var firestoreId: String?

    /// 同期済みフラグ
    var isSynced: Bool

    // MARK: - Computed Properties

    /// ロール（enum）
    var role: MemberRole {
        get { MemberRole(rawValue: roleRawValue) ?? .member }
        set { roleRawValue = newValue.rawValue }
    }

    /// オーナーかどうか
    var isOwner: Bool {
        role == .owner
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        userId: String,
        displayName: String,
        email: String = "",
        groupId: UUID,
        role: MemberRole = .member,
        joinedAt: Date = Date(),
        lastActiveAt: Date = Date(),
        firestoreId: String? = nil,
        isSynced: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.displayName = displayName
        self.email = email
        self.groupId = groupId
        self.roleRawValue = role.rawValue
        self.joinedAt = joinedAt
        self.lastActiveAt = lastActiveAt
        self.firestoreId = firestoreId
        self.isSynced = isSynced
    }

    // MARK: - Methods

    /// 最終アクティブ日時を更新
    func updateLastActive() {
        lastActiveAt = Date()
    }
}

// MARK: - Identifiable

extension LocalMember: Identifiable {}

// MARK: - Sample Data

extension LocalMember {
    /// プレビュー用サンプルデータ
    static func sampleMembers(for groupId: UUID) -> [LocalMember] {
        [
            LocalMember(
                userId: "user1",
                displayName: "パパ",
                email: "papa@example.com",
                groupId: groupId,
                role: .owner
            ),
            LocalMember(
                userId: "user2",
                displayName: "ママ",
                email: "mama@example.com",
                groupId: groupId,
                role: .member
            ),
            LocalMember(
                userId: "user3",
                displayName: "おじいちゃん",
                email: "grandpa@example.com",
                groupId: groupId,
                role: .member
            ),
            LocalMember(
                userId: "user4",
                displayName: "おばあちゃん",
                email: "grandma@example.com",
                groupId: groupId,
                role: .member
            )
        ]
    }
}
