//
//  SampleDataService.swift
//  AsaCrowdsource
//
//  デモ動画撮影用のサンプルデータを生成するサービス
//  田中家のグループ + 4メンバー + 5アイデア + コメント・投票を一括投入
//

import Foundation
import SwiftData

/// サンプルデータサービス
@ModelActor
actor SampleDataService {
    // MARK: - Public Methods

    /// サンプルデータを一括投入（田中家のグループ + メンバー4人 + アイデア5件）
    /// - Parameter ownerUserId: オーナーになるユーザーID（自動サインインしたゲストユーザーのID）
    func loadSampleData(ownerUserId: String) throws {
        let now = Date()
        let calendar = Calendar.current

        // 1. グループを作成
        let group = LocalFamilyGroup(
            name: "田中家",
            groupDescription: "家族みんなでアイデアを共有しよう！",
            ownerId: ownerUserId,
            inviteCode: "TANAKA",
            createdAt: calendar.date(byAdding: .day, value: -30, to: now) ?? now,
            updatedAt: now
        )
        modelContext.insert(group)
        let groupIdString = group.id.uuidString

        // 2. メンバーを追加（オーナー含む4名）
        let papaMember = LocalMember(
            userId: ownerUserId,
            displayName: "パパ",
            email: "papa@tanaka.example",
            groupId: group.id,
            role: .owner,
            joinedAt: calendar.date(byAdding: .day, value: -30, to: now) ?? now
        )
        let mamaMember = LocalMember(
            userId: "demo_user_mama",
            displayName: "ママ",
            email: "mama@tanaka.example",
            groupId: group.id,
            role: .member,
            joinedAt: calendar.date(byAdding: .day, value: -29, to: now) ?? now
        )
        let grandpaMember = LocalMember(
            userId: "demo_user_grandpa",
            displayName: "おじいちゃん",
            email: "grandpa@tanaka.example",
            groupId: group.id,
            role: .member,
            joinedAt: calendar.date(byAdding: .day, value: -25, to: now) ?? now
        )
        let grandmaMember = LocalMember(
            userId: "demo_user_grandma",
            displayName: "おばあちゃん",
            email: "grandma@tanaka.example",
            groupId: group.id,
            role: .member,
            joinedAt: calendar.date(byAdding: .day, value: -25, to: now) ?? now
        )
        modelContext.insert(papaMember)
        modelContext.insert(mamaMember)
        modelContext.insert(grandpaMember)
        modelContext.insert(grandmaMember)

        // 3. アイデアを5件作成
        let idea1 = createIdea(
            title: "夏休みの沖縄旅行",
            description: "8月のお盆休みに家族で沖縄旅行はどうでしょうか？美ら海水族館と首里城を見たいです。3泊4日でレンタカー移動を考えています。",
            category: .familyTrip,
            status: .discussing,
            authorId: ownerUserId,
            authorName: "パパ",
            groupId: groupIdString,
            daysAgo: 5
        )
        let idea2 = createIdea(
            title: "週末のBBQパーティー",
            description: "来週の土曜日、庭でBBQをしませんか？お肉と野菜をたくさん用意します。みんなで楽しい時間を過ごしましょう！",
            category: .weekend,
            status: .approved,
            authorId: "demo_user_mama",
            authorName: "ママ",
            groupId: groupIdString,
            daysAgo: 7
        )
        let idea3 = createIdea(
            title: "毎朝のラジオ体操",
            description: "家族みんなで朝のラジオ体操を始めませんか？健康のためにも、家族の交流のためにも良いと思います。",
            category: .health,
            status: .inProgress,
            authorId: "demo_user_grandpa",
            authorName: "おじいちゃん",
            groupId: groupIdString,
            daysAgo: 10
        )
        let idea4 = createIdea(
            title: "新しい本棚の購入",
            description: "子供部屋に本棚が必要です。IKEAで探してみましょう。サイズは幅80cm、高さ180cmくらいが良いと思います。",
            category: .shopping,
            status: .completed,
            authorId: ownerUserId,
            authorName: "パパ",
            groupId: groupIdString,
            daysAgo: 14
        )
        let idea5 = createIdea(
            title: "おばあちゃんの誕生日サプライズ",
            description: "来月のおばあちゃんの誕生日にサプライズパーティーを計画しませんか？ケーキとプレゼントの準備が必要です。",
            category: .event,
            status: .proposed,
            authorId: "demo_user_mama",
            authorName: "ママ",
            groupId: groupIdString,
            daysAgo: 2
        )

        let allIdeas = [idea1, idea2, idea3, idea4, idea5]
        for idea in allIdeas {
            modelContext.insert(idea)
        }

        // 4. コメントを追加
        addComments(to: idea1, comments: [
            ("demo_user_mama", "ママ", "賛成！沖縄行きたい〜🏖️", 4),
            ("demo_user_grandpa", "おじいちゃん", "私も行きたいですね。8月のお盆は混みますか？", 3),
            ("demo_user_grandma", "おばあちゃん", "孫たちと一緒に水族館行きたい💕", 2),
        ])
        addComments(to: idea2, comments: [
            (ownerUserId, "パパ", "いいですね！お肉は準備します", 6),
            ("demo_user_grandpa", "おじいちゃん", "野菜は私が育てたものを持っていきます", 5),
        ])
        addComments(to: idea3, comments: [
            (ownerUserId, "パパ", "毎朝6時にどうですか？", 9),
            ("demo_user_mama", "ママ", "賛成です！子供たちと一緒にやります", 8),
        ])
        addComments(to: idea4, comments: [
            ("demo_user_mama", "ママ", "とても気に入りました！ありがとう", 13),
        ])
        addComments(to: idea5, comments: [
            ("demo_user_grandpa", "おじいちゃん", "おばあちゃんには内緒で進めましょう👍", 1),
            (ownerUserId, "パパ", "ケーキは予約しておきます", 1),
        ])

        // 5. 投票を追加
        addVotes(to: idea1, votes: [
            ("demo_user_mama", "ママ", .love),
            ("demo_user_grandpa", "おじいちゃん", .interested),
            ("demo_user_grandma", "おばあちゃん", .love),
        ])
        addVotes(to: idea2, votes: [
            (ownerUserId, "パパ", .like),
            ("demo_user_grandpa", "おじいちゃん", .like),
            ("demo_user_grandma", "おばあちゃん", .interested),
        ])
        addVotes(to: idea3, votes: [
            (ownerUserId, "パパ", .like),
            ("demo_user_mama", "ママ", .love),
            ("demo_user_grandma", "おばあちゃん", .like),
        ])
        addVotes(to: idea4, votes: [
            ("demo_user_mama", "ママ", .love),
            ("demo_user_grandpa", "おじいちゃん", .like),
        ])
        addVotes(to: idea5, votes: [
            (ownerUserId, "パパ", .love),
            ("demo_user_grandpa", "おじいちゃん", .interested),
        ])

        // 6. 一括保存
        try modelContext.save()
    }

    // MARK: - Private Helpers

    /// アイデアを作成（保存はしない）
    private func createIdea(
        title: String,
        description: String,
        category: IdeaCategory,
        status: IdeaStatus,
        authorId: String,
        authorName: String,
        groupId: String,
        daysAgo: Int
    ) -> Idea {
        let now = Date()
        let calendar = Calendar.current
        let createdAt = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now

        return Idea(
            title: title,
            ideaDescription: description,
            category: category,
            status: status,
            authorId: authorId,
            authorName: authorName,
            groupId: groupId,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }

    /// コメントを追加（アイデアの commentCount も更新）
    private func addComments(to idea: Idea, comments: [(String, String, String, Int)]) {
        let now = Date()
        let calendar = Calendar.current

        for (userId, userName, content, hoursAgo) in comments {
            let comment = Comment(
                content: content,
                ideaId: idea.id,
                authorId: userId,
                authorName: userName,
                createdAt: calendar.date(byAdding: .hour, value: -hoursAgo, to: now) ?? now
            )
            modelContext.insert(comment)
        }
        idea.updateCommentCount(comments.count)
    }

    /// 投票を追加（アイデアの voteCount も更新）
    private func addVotes(to idea: Idea, votes: [(String, String, VoteType)]) {
        let now = Date()
        let calendar = Calendar.current

        for (index, voteData) in votes.enumerated() {
            let (userId, userName, type) = voteData
            let vote = Vote(
                type: type,
                ideaId: idea.id,
                userId: userId,
                userName: userName,
                createdAt: calendar.date(byAdding: .hour, value: -index, to: now) ?? now
            )
            modelContext.insert(vote)
        }
        idea.updateVoteCount(votes.count)
    }
}
