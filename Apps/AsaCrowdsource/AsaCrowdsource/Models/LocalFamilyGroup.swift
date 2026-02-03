//
//  LocalFamilyGroup.swift
//  AsaCrowdsource
//
//  家族グループのデータモデル（ローカル用）
//

import Foundation
import SwiftData

/// 家族グループモデル（SwiftData用）
@Model
final class LocalFamilyGroup {
    // MARK: - Properties

    /// 一意のID
    @Attribute(.unique) var id: UUID

    /// グループ名
    var name: String

    /// グループの説明
    var groupDescription: String

    /// オーナー（作成者）ID
    var ownerId: String

    /// 招待コード（6文字）
    var inviteCode: String

    /// 最大メンバー数
    var maxMembers: Int

    /// 作成日時
    var createdAt: Date

    /// 更新日時
    var updatedAt: Date

    /// Firebase連携用ID
    var firestoreId: String?

    /// 同期済みフラグ
    var isSynced: Bool

    // MARK: - Computed Properties

    /// 招待コードの表示用フォーマット
    var formattedInviteCode: String {
        inviteCode.uppercased()
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        name: String,
        groupDescription: String = "",
        ownerId: String,
        inviteCode: String? = nil,
        maxMembers: Int = 10,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        firestoreId: String? = nil,
        isSynced: Bool = false
    ) {
        self.id = id
        self.name = name
        self.groupDescription = groupDescription
        self.ownerId = ownerId
        self.inviteCode = inviteCode ?? Self.generateInviteCode()
        self.maxMembers = maxMembers
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.firestoreId = firestoreId
        self.isSynced = isSynced
    }

    // MARK: - Methods

    /// 招待コードを再生成
    func regenerateInviteCode() {
        inviteCode = Self.generateInviteCode()
        updatedAt = Date()
    }

    /// 招待コード生成（6文字の英数字）
    static func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // 紛らわしい文字を除外
        return String((0..<6).map { _ in characters.randomElement()! })
    }
}

// MARK: - Identifiable

extension LocalFamilyGroup: Identifiable {}

// MARK: - Sample Data

extension LocalFamilyGroup {
    /// プレビュー用サンプルデータ
    static var sampleGroup: LocalFamilyGroup {
        LocalFamilyGroup(
            name: "田中家",
            groupDescription: "田中家のファミリーグループです",
            ownerId: "user1",
            inviteCode: "ABC123"
        )
    }
}
