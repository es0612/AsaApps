//
//  Vote.swift
//  AsaCrowdsource
//
//  投票のデータモデル
//

import Foundation
import SwiftData

/// 投票モデル
@Model
final class Vote {
    // MARK: - Properties

    /// 一意のID
    @Attribute(.unique) var id: UUID

    /// 投票タイプ（rawValue保存）
    var typeRawValue: String

    /// 対象アイデアID
    var ideaId: UUID

    /// 投票者ID
    var userId: String

    /// 投票者名
    var userName: String

    /// 作成日時
    var createdAt: Date

    /// Firebase連携用ID
    var firestoreId: String?

    /// 同期済みフラグ
    var isSynced: Bool

    // MARK: - Computed Properties

    /// 投票タイプ（enum）
    var type: VoteType {
        get { VoteType(rawValue: typeRawValue) ?? .like }
        set { typeRawValue = newValue.rawValue }
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        type: VoteType,
        ideaId: UUID,
        userId: String,
        userName: String,
        createdAt: Date = Date(),
        firestoreId: String? = nil,
        isSynced: Bool = false
    ) {
        self.id = id
        self.typeRawValue = type.rawValue
        self.ideaId = ideaId
        self.userId = userId
        self.userName = userName
        self.createdAt = createdAt
        self.firestoreId = firestoreId
        self.isSynced = isSynced
    }
}

// MARK: - Identifiable

extension Vote: Identifiable {}

// MARK: - Sample Data

extension Vote {
    /// プレビュー用サンプルデータ
    static func sampleVotes(for ideaId: UUID) -> [Vote] {
        [
            Vote(
                type: .love,
                ideaId: ideaId,
                userId: "user2",
                userName: "ママ",
                createdAt: Date().addingTimeInterval(-7200)
            ),
            Vote(
                type: .like,
                ideaId: ideaId,
                userId: "user3",
                userName: "おじいちゃん",
                createdAt: Date().addingTimeInterval(-3600)
            ),
            Vote(
                type: .interested,
                ideaId: ideaId,
                userId: "user4",
                userName: "おばあちゃん",
                createdAt: Date().addingTimeInterval(-1800)
            )
        ]
    }
}

// MARK: - Vote Summary

/// 投票集計サマリー
struct VoteSummary: Equatable, Sendable {
    let likeCount: Int
    let loveCount: Int
    let interestedCount: Int

    var totalCount: Int {
        likeCount + loveCount + interestedCount
    }

    /// 重み付けスコア（優先度計算用）
    var weightedScore: Int {
        (likeCount * VoteType.like.weight) +
        (loveCount * VoteType.love.weight) +
        (interestedCount * VoteType.interested.weight)
    }

    init(likeCount: Int = 0, loveCount: Int = 0, interestedCount: Int = 0) {
        self.likeCount = likeCount
        self.loveCount = loveCount
        self.interestedCount = interestedCount
    }

    init(votes: [Vote]) {
        self.likeCount = votes.filter { $0.type == .like }.count
        self.loveCount = votes.filter { $0.type == .love }.count
        self.interestedCount = votes.filter { $0.type == .interested }.count
    }

    static let empty = VoteSummary()
}
