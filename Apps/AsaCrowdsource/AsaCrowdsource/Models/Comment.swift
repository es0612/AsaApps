//
//  Comment.swift
//  AsaCrowdsource
//
//  コメントのデータモデル
//

import Foundation
import SwiftData

/// コメントモデル
@Model
final class Comment {
    // MARK: - Properties

    /// 一意のID
    @Attribute(.unique) var id: UUID

    /// コメント本文（最大500文字）
    var content: String

    /// 対象アイデアID
    var ideaId: UUID

    /// 作成者ID
    var authorId: String

    /// 作成者名
    var authorName: String

    /// 作成日時
    var createdAt: Date

    /// 更新日時
    var updatedAt: Date

    /// Firebase連携用ID
    var firestoreId: String?

    /// 同期済みフラグ
    var isSynced: Bool

    // MARK: - Computed Properties

    /// コンテンツのバリデーション（500文字以内）
    var isValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        content.count <= 500
    }

    /// 編集されたかどうか
    var isEdited: Bool {
        updatedAt.timeIntervalSince(createdAt) > 1.0
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        content: String,
        ideaId: UUID,
        authorId: String,
        authorName: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        firestoreId: String? = nil,
        isSynced: Bool = false
    ) {
        self.id = id
        self.content = content
        self.ideaId = ideaId
        self.authorId = authorId
        self.authorName = authorName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.firestoreId = firestoreId
        self.isSynced = isSynced
    }

    // MARK: - Methods

    /// コンテンツを更新
    func update(content: String) {
        self.content = content
        self.updatedAt = Date()
    }
}

// MARK: - Identifiable

extension Comment: Identifiable {}

// MARK: - Sample Data

extension Comment {
    /// プレビュー用サンプルデータ
    static func sampleComments(for ideaId: UUID) -> [Comment] {
        [
            Comment(
                content: "いいアイデアですね！ぜひ実現したいです。",
                ideaId: ideaId,
                authorId: "user2",
                authorName: "ママ",
                createdAt: Date().addingTimeInterval(-3600)
            ),
            Comment(
                content: "予算はどれくらいを想定していますか？",
                ideaId: ideaId,
                authorId: "user3",
                authorName: "おじいちゃん",
                createdAt: Date().addingTimeInterval(-1800)
            ),
            Comment(
                content: "日程を調整しましょう！",
                ideaId: ideaId,
                authorId: "user1",
                authorName: "パパ",
                createdAt: Date().addingTimeInterval(-900)
            )
        ]
    }
}
