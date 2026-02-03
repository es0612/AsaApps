//
//  IdeaListViewModel.swift
//  AsaCrowdsource
//
//  アイデア一覧を管理するViewModel
//

import Foundation
import SwiftUI
import SwiftData

/// ソート順
enum IdeaSortOrder: String, CaseIterable, Identifiable {
    case newest = "newest"
    case oldest = "oldest"
    case mostVotes = "most_votes"
    case mostComments = "most_comments"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .newest: return "新しい順"
        case .oldest: return "古い順"
        case .mostVotes: return "投票数順"
        case .mostComments: return "コメント数順"
        }
    }
}

/// アイデア一覧ViewModel
@MainActor
@Observable
final class IdeaListViewModel {
    // MARK: - Properties

    private(set) var ideas: [Idea] = []
    private(set) var filteredIdeas: [Idea] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // フィルター設定
    var selectedCategory: IdeaCategory?
    var selectedStatus: IdeaStatus?
    var sortOrder: IdeaSortOrder = .newest
    var searchText: String = ""

    // MARK: - Private Properties

    private var dataService: LocalDataService?
    private var groupId: String?

    // MARK: - Computed Properties

    var hasIdeas: Bool {
        !filteredIdeas.isEmpty
    }

    var activeIdeasCount: Int {
        ideas.filter { $0.status.isActive }.count
    }

    var completedIdeasCount: Int {
        ideas.filter { $0.status == .completed }.count
    }

    // MARK: - Public Methods

    /// データサービスを設定
    func setDataService(_ service: LocalDataService) {
        self.dataService = service
    }

    /// グループIDを設定
    func setGroupId(_ id: String) {
        self.groupId = id
    }

    /// アイデア一覧を読み込み
    func loadIdeas() async {
        guard let dataService = dataService, let groupId = groupId else { return }

        isLoading = true
        errorMessage = nil

        do {
            ideas = try await dataService.fetchIdeas(groupId: groupId)
            applyFilters()
        } catch {
            errorMessage = "アイデアの読み込みに失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// フィルターを適用
    func applyFilters() {
        var result = ideas

        // カテゴリフィルター
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // ステータスフィルター
        if let status = selectedStatus {
            result = result.filter { $0.status == status }
        }

        // 検索テキストフィルター
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(lowercasedSearch) ||
                $0.ideaDescription.lowercased().contains(lowercasedSearch) ||
                $0.authorName.lowercased().contains(lowercasedSearch)
            }
        }

        // ソート
        result = sortIdeas(result)

        filteredIdeas = result
    }

    /// カテゴリフィルターをクリア
    func clearCategoryFilter() {
        selectedCategory = nil
        applyFilters()
    }

    /// ステータスフィルターをクリア
    func clearStatusFilter() {
        selectedStatus = nil
        applyFilters()
    }

    /// すべてのフィルターをクリア
    func clearAllFilters() {
        selectedCategory = nil
        selectedStatus = nil
        searchText = ""
        sortOrder = .newest
        applyFilters()
    }

    /// アイデアを削除
    func deleteIdea(id: UUID, authorId: String) async {
        guard let dataService = dataService else { return }

        do {
            try await dataService.deleteIdea(id: id, authorId: authorId)
            ideas.removeAll { $0.id == id }
            applyFilters()
        } catch {
            errorMessage = "アイデアの削除に失敗しました"
        }
    }

    /// アイデアのステータスを更新
    func updateIdeaStatus(id: UUID, status: IdeaStatus) async {
        guard let dataService = dataService else { return }

        do {
            try await dataService.updateIdeaStatus(id: id, status: status)
            if let index = ideas.firstIndex(where: { $0.id == id }) {
                ideas[index].status = status
            }
            applyFilters()
        } catch {
            errorMessage = "ステータスの更新に失敗しました"
        }
    }

    /// 新しいアイデアをリストに追加（外部からの追加用）
    func addIdea(_ idea: Idea) {
        ideas.insert(idea, at: 0)
        applyFilters()
    }

    /// アイデアを更新（外部からの更新用）
    func updateIdea(_ idea: Idea) {
        if let index = ideas.firstIndex(where: { $0.id == idea.id }) {
            ideas[index] = idea
            applyFilters()
        }
    }

    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Methods

    private func sortIdeas(_ ideas: [Idea]) -> [Idea] {
        switch sortOrder {
        case .newest:
            return ideas.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return ideas.sorted { $0.createdAt < $1.createdAt }
        case .mostVotes:
            return ideas.sorted { $0.voteCount > $1.voteCount }
        case .mostComments:
            return ideas.sorted { $0.commentCount > $1.commentCount }
        }
    }
}
