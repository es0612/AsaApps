//
//  Idea.swift
//  AsaCrowdsource
//
//  アイデアのデータモデル
//

import Foundation
import SwiftData

/// アイデアモデル
@Model
final class Idea {
    // MARK: - Properties

    /// 一意のID
    @Attribute(.unique) var id: UUID

    /// タイトル（必須、最大100文字）
    var title: String

    /// 説明（任意、最大1000文字）
    var ideaDescription: String

    /// カテゴリ（rawValue保存）
    var categoryRawValue: String

    /// ステータス（rawValue保存）
    var statusRawValue: String

    /// 作成者ID
    var authorId: String

    /// 作成者名
    var authorName: String

    /// グループID
    var groupId: String

    /// 作成日時
    var createdAt: Date

    /// 更新日時
    var updatedAt: Date

    /// 投票数（キャッシュ）
    var voteCount: Int

    /// コメント数（キャッシュ）
    var commentCount: Int

    /// Firebase連携用ID
    var firestoreId: String?

    /// 同期済みフラグ
    var isSynced: Bool

    // MARK: - Computed Properties

    /// カテゴリ（enum）
    var category: IdeaCategory {
        get { IdeaCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    /// ステータス（enum）
    var status: IdeaStatus {
        get { IdeaStatus(rawValue: statusRawValue) ?? .proposed }
        set { statusRawValue = newValue.rawValue }
    }

    /// タイトルのバリデーション（100文字以内）
    var isTitleValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        title.count <= 100
    }

    /// 説明のバリデーション（1000文字以内）
    var isDescriptionValid: Bool {
        ideaDescription.count <= 1000
    }

    /// アイデアが編集可能かどうか
    var isEditable: Bool {
        status != .completed && status != .archived
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        title: String,
        ideaDescription: String = "",
        category: IdeaCategory = .other,
        status: IdeaStatus = .proposed,
        authorId: String,
        authorName: String,
        groupId: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        voteCount: Int = 0,
        commentCount: Int = 0,
        firestoreId: String? = nil,
        isSynced: Bool = false
    ) {
        self.id = id
        self.title = title
        self.ideaDescription = ideaDescription
        self.categoryRawValue = category.rawValue
        self.statusRawValue = status.rawValue
        self.authorId = authorId
        self.authorName = authorName
        self.groupId = groupId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.voteCount = voteCount
        self.commentCount = commentCount
        self.firestoreId = firestoreId
        self.isSynced = isSynced
    }

    // MARK: - Methods

    /// ステータスを次に進める
    func progressStatus() {
        if let next = status.nextStatus {
            status = next
            updatedAt = Date()
        }
    }

    /// アーカイブする
    func archive() {
        status = .archived
        updatedAt = Date()
    }

    /// 投票数を更新
    func updateVoteCount(_ count: Int) {
        voteCount = count
        updatedAt = Date()
    }

    /// コメント数を更新
    func updateCommentCount(_ count: Int) {
        commentCount = count
        updatedAt = Date()
    }
}

// MARK: - Identifiable

extension Idea: Identifiable {}

// MARK: - Sample Data

extension Idea {
    /// プレビュー用サンプルデータ
    static var sampleIdeas: [Idea] {
        [
            Idea(
                title: "夏休みの沖縄旅行",
                ideaDescription: "8月のお盆休みに家族で沖縄旅行はどうでしょうか？美ら海水族館と首里城を見たいです。",
                category: .familyTrip,
                status: .discussing,
                authorId: "user1",
                authorName: "パパ",
                groupId: "group1",
                voteCount: 5,
                commentCount: 3
            ),
            Idea(
                title: "週末のBBQ",
                ideaDescription: "来週の土曜日、庭でBBQをしませんか？",
                category: .weekend,
                status: .proposed,
                authorId: "user2",
                authorName: "ママ",
                groupId: "group1",
                voteCount: 3,
                commentCount: 1
            ),
            Idea(
                title: "新しい本棚の購入",
                ideaDescription: "子供部屋に本棚が必要です。IKEAで探してみましょう。",
                category: .shopping,
                status: .approved,
                authorId: "user1",
                authorName: "パパ",
                groupId: "group1",
                voteCount: 2,
                commentCount: 0
            ),
            Idea(
                title: "毎朝のストレッチ習慣",
                ideaDescription: "家族みんなで朝5分のストレッチを始めませんか？",
                category: .health,
                status: .inProgress,
                authorId: "user2",
                authorName: "ママ",
                groupId: "group1",
                voteCount: 4,
                commentCount: 2
            )
        ]
    }
}
