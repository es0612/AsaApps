//
//  LocalDataService.swift
//  AsaCrowdsource
//
//  SwiftDataを使用したローカルデータサービス実装
//

import Foundation
import SwiftData

/// SwiftDataを使用したローカルデータサービス
@ModelActor
actor LocalDataService: CrowdsourceDataServiceProtocol {

    // MARK: - GroupDataServiceProtocol

    func createGroup(name: String, description: String, ownerId: String) async throws -> LocalFamilyGroup {
        let group = LocalFamilyGroup(
            name: name,
            groupDescription: description,
            ownerId: ownerId
        )
        modelContext.insert(group)

        // オーナーをメンバーとして追加
        let ownerMember = LocalMember(
            userId: ownerId,
            displayName: "オーナー",
            groupId: group.id,
            role: .owner
        )
        modelContext.insert(ownerMember)

        try modelContext.save()
        return group
    }

    func joinGroup(inviteCode: String, userId: String, displayName: String) async throws -> LocalFamilyGroup {
        guard let group = try await findGroup(byInviteCode: inviteCode) else {
            throw DataServiceError.invalidInviteCode
        }

        // 既にメンバーかチェック
        if let _ = try await fetchMember(userId: userId, groupId: group.id) {
            throw DataServiceError.alreadyMember
        }

        // メンバー数チェック
        let members = try await fetchMembers(groupId: group.id)
        if members.count >= group.maxMembers {
            throw DataServiceError.maxMembersReached
        }

        // メンバーとして追加
        let member = LocalMember(
            userId: userId,
            displayName: displayName,
            groupId: group.id,
            role: .member
        )
        modelContext.insert(member)
        try modelContext.save()

        return group
    }

    func fetchGroup(id: UUID) async throws -> LocalFamilyGroup? {
        let descriptor = FetchDescriptor<LocalFamilyGroup>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchUserGroups(userId: String) async throws -> [LocalFamilyGroup] {
        // ユーザーが所属するグループIDを取得
        let memberDescriptor = FetchDescriptor<LocalMember>(
            predicate: #Predicate { $0.userId == userId }
        )
        let members = try modelContext.fetch(memberDescriptor)
        let groupIds = members.map { $0.groupId }

        // グループを取得
        var groups: [LocalFamilyGroup] = []
        for groupId in groupIds {
            if let group = try await fetchGroup(id: groupId) {
                groups.append(group)
            }
        }
        return groups.sorted { $0.createdAt > $1.createdAt }
    }

    func findGroup(byInviteCode code: String) async throws -> LocalFamilyGroup? {
        let upperCode = code.uppercased()
        let descriptor = FetchDescriptor<LocalFamilyGroup>(
            predicate: #Predicate { $0.inviteCode == upperCode }
        )
        return try modelContext.fetch(descriptor).first
    }

    func updateGroup(_ group: LocalFamilyGroup) async throws {
        group.updatedAt = Date()
        try modelContext.save()
    }

    func regenerateInviteCode(groupId: UUID) async throws -> String {
        guard let group = try await fetchGroup(id: groupId) else {
            throw DataServiceError.groupNotFound
        }
        group.regenerateInviteCode()
        try modelContext.save()
        return group.inviteCode
    }

    func leaveGroup(groupId: UUID, userId: String) async throws {
        try await removeMember(userId: userId, groupId: groupId)
    }

    func deleteGroup(id: UUID, ownerId: String) async throws {
        guard let group = try await fetchGroup(id: id) else {
            throw DataServiceError.groupNotFound
        }
        guard group.ownerId == ownerId else {
            throw DataServiceError.notAuthorized
        }

        // メンバーを削除
        let members = try await fetchMembers(groupId: id)
        for member in members {
            modelContext.delete(member)
        }

        // アイデア、コメント、投票を削除
        let ideas = try await fetchIdeas(groupId: id.uuidString)
        for idea in ideas {
            let comments = try await fetchComments(ideaId: idea.id)
            for comment in comments {
                modelContext.delete(comment)
            }
            let votes = try await fetchVotes(ideaId: idea.id)
            for vote in votes {
                modelContext.delete(vote)
            }
            modelContext.delete(idea)
        }

        // グループを削除
        modelContext.delete(group)
        try modelContext.save()
    }

    // MARK: - MemberDataServiceProtocol

    func fetchMembers(groupId: UUID) async throws -> [LocalMember] {
        let descriptor = FetchDescriptor<LocalMember>(
            predicate: #Predicate { $0.groupId == groupId },
            sortBy: [SortDescriptor(\.joinedAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchMember(userId: String, groupId: UUID) async throws -> LocalMember? {
        let descriptor = FetchDescriptor<LocalMember>(
            predicate: #Predicate { $0.userId == userId && $0.groupId == groupId }
        )
        return try modelContext.fetch(descriptor).first
    }

    func addMember(_ member: LocalMember) async throws {
        modelContext.insert(member)
        try modelContext.save()
    }

    func updateMember(_ member: LocalMember) async throws {
        member.lastActiveAt = Date()
        try modelContext.save()
    }

    func removeMember(userId: String, groupId: UUID) async throws {
        guard let member = try await fetchMember(userId: userId, groupId: groupId) else {
            throw DataServiceError.memberNotFound
        }
        modelContext.delete(member)
        try modelContext.save()
    }

    // MARK: - IdeaDataServiceProtocol

    func createIdea(_ idea: Idea) async throws -> Idea {
        modelContext.insert(idea)
        try modelContext.save()
        return idea
    }

    func fetchIdeas(groupId: String) async throws -> [Idea] {
        let descriptor = FetchDescriptor<Idea>(
            predicate: #Predicate { $0.groupId == groupId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchIdeas(groupId: String, category: IdeaCategory?, status: IdeaStatus?) async throws -> [Idea] {
        var ideas = try await fetchIdeas(groupId: groupId)

        if let category = category {
            ideas = ideas.filter { $0.category == category }
        }

        if let status = status {
            ideas = ideas.filter { $0.status == status }
        }

        return ideas
    }

    func fetchIdea(id: UUID) async throws -> Idea? {
        let descriptor = FetchDescriptor<Idea>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func updateIdea(_ idea: Idea) async throws {
        idea.updatedAt = Date()
        try modelContext.save()
    }

    func updateIdeaStatus(id: UUID, status: IdeaStatus) async throws {
        guard let idea = try await fetchIdea(id: id) else {
            throw DataServiceError.ideaNotFound
        }
        idea.status = status
        idea.updatedAt = Date()
        try modelContext.save()
    }

    func deleteIdea(id: UUID, authorId: String) async throws {
        guard let idea = try await fetchIdea(id: id) else {
            throw DataServiceError.ideaNotFound
        }
        guard idea.authorId == authorId else {
            throw DataServiceError.notAuthorized
        }

        // 関連するコメントと投票を削除
        let comments = try await fetchComments(ideaId: id)
        for comment in comments {
            modelContext.delete(comment)
        }

        let votes = try await fetchVotes(ideaId: id)
        for vote in votes {
            modelContext.delete(vote)
        }

        modelContext.delete(idea)
        try modelContext.save()
    }

    // MARK: - CommentDataServiceProtocol

    func createComment(_ comment: Comment) async throws -> Comment {
        modelContext.insert(comment)

        // アイデアのコメント数を更新
        if let idea = try await fetchIdea(id: comment.ideaId) {
            let comments = try await fetchComments(ideaId: idea.id)
            idea.updateCommentCount(comments.count + 1)
        }

        try modelContext.save()
        return comment
    }

    func fetchComments(ideaId: UUID) async throws -> [Comment] {
        let descriptor = FetchDescriptor<Comment>(
            predicate: #Predicate { $0.ideaId == ideaId },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    func updateComment(_ comment: Comment) async throws {
        comment.updatedAt = Date()
        try modelContext.save()
    }

    func deleteComment(id: UUID, authorId: String) async throws {
        let descriptor = FetchDescriptor<Comment>(
            predicate: #Predicate { $0.id == id }
        )
        guard let comment = try modelContext.fetch(descriptor).first else {
            throw DataServiceError.commentNotFound
        }
        guard comment.authorId == authorId else {
            throw DataServiceError.notAuthorized
        }

        let ideaId = comment.ideaId
        modelContext.delete(comment)

        // アイデアのコメント数を更新
        if let idea = try await fetchIdea(id: ideaId) {
            let comments = try await fetchComments(ideaId: ideaId)
            idea.updateCommentCount(comments.count - 1)
        }

        try modelContext.save()
    }

    // MARK: - VoteDataServiceProtocol

    func vote(ideaId: UUID, userId: String, userName: String, type: VoteType) async throws -> Vote {
        // 既存の投票を確認
        if let existingVote = try await fetchUserVote(ideaId: ideaId, userId: userId) {
            // 同じタイプなら削除（トグル動作）
            if existingVote.type == type {
                try await removeVote(ideaId: ideaId, userId: userId)
                throw DataServiceError.voteNotFound // 投票が削除されたことを示す
            }
            // 異なるタイプなら更新
            existingVote.type = type
            try await updateVoteCount(ideaId: ideaId)
            try modelContext.save()
            return existingVote
        }

        // 新規投票を作成
        let vote = Vote(
            type: type,
            ideaId: ideaId,
            userId: userId,
            userName: userName
        )
        modelContext.insert(vote)
        try await updateVoteCount(ideaId: ideaId)
        try modelContext.save()
        return vote
    }

    func fetchVotes(ideaId: UUID) async throws -> [Vote] {
        let descriptor = FetchDescriptor<Vote>(
            predicate: #Predicate { $0.ideaId == ideaId },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchUserVote(ideaId: UUID, userId: String) async throws -> Vote? {
        let descriptor = FetchDescriptor<Vote>(
            predicate: #Predicate { $0.ideaId == ideaId && $0.userId == userId }
        )
        return try modelContext.fetch(descriptor).first
    }

    func removeVote(ideaId: UUID, userId: String) async throws {
        guard let vote = try await fetchUserVote(ideaId: ideaId, userId: userId) else {
            throw DataServiceError.voteNotFound
        }
        modelContext.delete(vote)
        try await updateVoteCount(ideaId: ideaId)
        try modelContext.save()
    }

    func fetchVoteSummary(ideaId: UUID) async throws -> VoteSummary {
        let votes = try await fetchVotes(ideaId: ideaId)
        return VoteSummary(votes: votes)
    }

    // MARK: - Private Methods

    private func updateVoteCount(ideaId: UUID) async throws {
        if let idea = try await fetchIdea(id: ideaId) {
            let votes = try await fetchVotes(ideaId: ideaId)
            idea.updateVoteCount(votes.count)
        }
    }
}
