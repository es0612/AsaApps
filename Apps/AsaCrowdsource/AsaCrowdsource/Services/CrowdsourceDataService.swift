//
//  CrowdsourceDataService.swift
//  AsaCrowdsource
//
//  データサービスのプロトコル定義
//

import Foundation

/// データサービスエラー
enum DataServiceError: Error, LocalizedError {
    case groupNotFound
    case ideaNotFound
    case commentNotFound
    case voteNotFound
    case memberNotFound
    case invalidInviteCode
    case maxMembersReached
    case alreadyMember
    case notAuthorized
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case syncFailed(Error)

    var errorDescription: String? {
        switch self {
        case .groupNotFound:
            return "グループが見つかりません"
        case .ideaNotFound:
            return "アイデアが見つかりません"
        case .commentNotFound:
            return "コメントが見つかりません"
        case .voteNotFound:
            return "投票が見つかりません"
        case .memberNotFound:
            return "メンバーが見つかりません"
        case .invalidInviteCode:
            return "招待コードが無効です"
        case .maxMembersReached:
            return "メンバー数が上限に達しています"
        case .alreadyMember:
            return "既にこのグループのメンバーです"
        case .notAuthorized:
            return "この操作を行う権限がありません"
        case .saveFailed(let error):
            return "保存に失敗しました: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "データの取得に失敗しました: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "削除に失敗しました: \(error.localizedDescription)"
        case .syncFailed(let error):
            return "同期に失敗しました: \(error.localizedDescription)"
        }
    }
}

// MARK: - Group Data Service Protocol

/// グループデータサービスプロトコル
protocol GroupDataServiceProtocol: Sendable {
    /// グループを作成
    func createGroup(name: String, description: String, ownerId: String) async throws -> LocalFamilyGroup

    /// 招待コードでグループに参加
    func joinGroup(inviteCode: String, userId: String, displayName: String) async throws -> LocalFamilyGroup

    /// グループを取得
    func fetchGroup(id: UUID) async throws -> LocalFamilyGroup?

    /// ユーザーが所属するグループを取得
    func fetchUserGroups(userId: String) async throws -> [LocalFamilyGroup]

    /// 招待コードでグループを検索
    func findGroup(byInviteCode code: String) async throws -> LocalFamilyGroup?

    /// グループを更新
    func updateGroup(_ group: LocalFamilyGroup) async throws

    /// 招待コードを再生成
    func regenerateInviteCode(groupId: UUID) async throws -> String

    /// グループから離脱
    func leaveGroup(groupId: UUID, userId: String) async throws

    /// グループを削除（オーナーのみ）
    func deleteGroup(id: UUID, ownerId: String) async throws
}

// MARK: - Member Data Service Protocol

/// メンバーデータサービスプロトコル
protocol MemberDataServiceProtocol: Sendable {
    /// メンバーを取得
    func fetchMembers(groupId: UUID) async throws -> [LocalMember]

    /// 特定のメンバーを取得
    func fetchMember(userId: String, groupId: UUID) async throws -> LocalMember?

    /// メンバーを追加
    func addMember(_ member: LocalMember) async throws

    /// メンバーを更新
    func updateMember(_ member: LocalMember) async throws

    /// メンバーを削除
    func removeMember(userId: String, groupId: UUID) async throws
}

// MARK: - Idea Data Service Protocol

/// アイデアデータサービスプロトコル
protocol IdeaDataServiceProtocol: Sendable {
    /// アイデアを作成
    func createIdea(_ idea: Idea) async throws -> Idea

    /// アイデア一覧を取得
    func fetchIdeas(groupId: String) async throws -> [Idea]

    /// アイデア一覧を取得（フィルタ付き）
    func fetchIdeas(groupId: String, category: IdeaCategory?, status: IdeaStatus?) async throws -> [Idea]

    /// 特定のアイデアを取得
    func fetchIdea(id: UUID) async throws -> Idea?

    /// アイデアを更新
    func updateIdea(_ idea: Idea) async throws

    /// アイデアのステータスを更新
    func updateIdeaStatus(id: UUID, status: IdeaStatus) async throws

    /// アイデアを削除
    func deleteIdea(id: UUID, authorId: String) async throws
}

// MARK: - Comment Data Service Protocol

/// コメントデータサービスプロトコル
protocol CommentDataServiceProtocol: Sendable {
    /// コメントを作成
    func createComment(_ comment: Comment) async throws -> Comment

    /// コメント一覧を取得
    func fetchComments(ideaId: UUID) async throws -> [Comment]

    /// コメントを更新
    func updateComment(_ comment: Comment) async throws

    /// コメントを削除
    func deleteComment(id: UUID, authorId: String) async throws
}

// MARK: - Vote Data Service Protocol

/// 投票データサービスプロトコル
protocol VoteDataServiceProtocol: Sendable {
    /// 投票を作成または更新
    func vote(ideaId: UUID, userId: String, userName: String, type: VoteType) async throws -> Vote

    /// 投票を取得
    func fetchVotes(ideaId: UUID) async throws -> [Vote]

    /// ユーザーの投票を取得
    func fetchUserVote(ideaId: UUID, userId: String) async throws -> Vote?

    /// 投票を削除（取り消し）
    func removeVote(ideaId: UUID, userId: String) async throws

    /// 投票サマリーを取得
    func fetchVoteSummary(ideaId: UUID) async throws -> VoteSummary
}

// MARK: - Combined Data Service Protocol

/// 統合データサービスプロトコル
protocol CrowdsourceDataServiceProtocol:
    GroupDataServiceProtocol,
    MemberDataServiceProtocol,
    IdeaDataServiceProtocol,
    CommentDataServiceProtocol,
    VoteDataServiceProtocol {}
