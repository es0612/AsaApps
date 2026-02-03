//
//  IdeaDetailViewModel.swift
//  AsaCrowdsource
//
//  アイデア詳細を管理するViewModel
//

import Foundation
import SwiftUI
import SwiftData

/// アイデア詳細ViewModel
@MainActor
@Observable
final class IdeaDetailViewModel {
    // MARK: - Properties

    var idea: Idea?
    private(set) var comments: [Comment] = []
    private(set) var votes: [Vote] = []
    private(set) var voteSummary: VoteSummary = .empty
    private(set) var userVote: Vote?
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Private Properties

    private var dataService: LocalDataService?
    private var currentUserId: String?
    private var currentUserName: String?

    // MARK: - Computed Properties

    var hasComments: Bool {
        !comments.isEmpty
    }

    var commentsCount: Int {
        comments.count
    }

    var canEdit: Bool {
        guard let idea = idea, let userId = currentUserId else { return false }
        return idea.authorId == userId && idea.isEditable
    }

    var canDelete: Bool {
        guard let idea = idea, let userId = currentUserId else { return false }
        return idea.authorId == userId
    }

    var canProgressStatus: Bool {
        idea?.status.canProgress ?? false
    }

    // MARK: - Public Methods

    /// データサービスを設定
    func setDataService(_ service: LocalDataService) {
        self.dataService = service
    }

    /// 現在のユーザー情報を設定
    func setCurrentUser(id: String, name: String) {
        self.currentUserId = id
        self.currentUserName = name
    }

    /// アイデア詳細を読み込み
    func loadIdea(id: UUID) async {
        guard let dataService = dataService else { return }

        isLoading = true
        errorMessage = nil

        do {
            idea = try await dataService.fetchIdea(id: id)
            if idea != nil {
                await loadComments()
                await loadVotes()
            }
        } catch {
            errorMessage = "アイデアの読み込みに失敗しました"
        }

        isLoading = false
    }

    /// コメントを読み込み
    func loadComments() async {
        guard let dataService = dataService, let idea = idea else { return }

        do {
            comments = try await dataService.fetchComments(ideaId: idea.id)
        } catch {
            errorMessage = "コメントの読み込みに失敗しました"
        }
    }

    /// 投票を読み込み
    func loadVotes() async {
        guard let dataService = dataService, let idea = idea else { return }

        do {
            votes = try await dataService.fetchVotes(ideaId: idea.id)
            voteSummary = VoteSummary(votes: votes)

            if let userId = currentUserId {
                userVote = try await dataService.fetchUserVote(ideaId: idea.id, userId: userId)
            }
        } catch {
            errorMessage = "投票の読み込みに失敗しました"
        }
    }

    /// コメントを追加
    func addComment(content: String) async {
        guard let dataService = dataService,
              let idea = idea,
              let userId = currentUserId,
              let userName = currentUserName else { return }

        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "コメントを入力してください"
            return
        }

        let comment = Comment(
            content: content,
            ideaId: idea.id,
            authorId: userId,
            authorName: userName
        )

        do {
            let savedComment = try await dataService.createComment(comment)
            comments.append(savedComment)
            self.idea?.updateCommentCount(comments.count)
        } catch {
            errorMessage = "コメントの投稿に失敗しました"
        }
    }

    /// コメントを削除
    func deleteComment(id: UUID) async {
        guard let dataService = dataService, let userId = currentUserId else { return }

        do {
            try await dataService.deleteComment(id: id, authorId: userId)
            comments.removeAll { $0.id == id }
            self.idea?.updateCommentCount(comments.count)
        } catch {
            errorMessage = "コメントの削除に失敗しました"
        }
    }

    /// 投票する
    func vote(type: VoteType) async {
        guard let dataService = dataService,
              let idea = idea,
              let userId = currentUserId,
              let userName = currentUserName else { return }

        do {
            let newVote = try await dataService.vote(
                ideaId: idea.id,
                userId: userId,
                userName: userName,
                type: type
            )
            userVote = newVote
            await loadVotes()
        } catch DataServiceError.voteNotFound {
            // 投票が削除された（トグル動作）
            userVote = nil
            await loadVotes()
        } catch {
            errorMessage = "投票に失敗しました"
        }
    }

    /// 投票を取り消す
    func removeVote() async {
        guard let dataService = dataService,
              let idea = idea,
              let userId = currentUserId else { return }

        do {
            try await dataService.removeVote(ideaId: idea.id, userId: userId)
            userVote = nil
            await loadVotes()
        } catch {
            errorMessage = "投票の取り消しに失敗しました"
        }
    }

    /// ステータスを次に進める
    func progressStatus() async {
        guard let dataService = dataService,
              let idea = idea,
              let nextStatus = idea.status.nextStatus else { return }

        do {
            try await dataService.updateIdeaStatus(id: idea.id, status: nextStatus)
            self.idea?.status = nextStatus
        } catch {
            errorMessage = "ステータスの更新に失敗しました"
        }
    }

    /// アイデアを削除
    func deleteIdea() async -> Bool {
        guard let dataService = dataService,
              let idea = idea,
              let userId = currentUserId else { return false }

        do {
            try await dataService.deleteIdea(id: idea.id, authorId: userId)
            return true
        } catch {
            errorMessage = "アイデアの削除に失敗しました"
            return false
        }
    }

    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }
}
