//
//  CreateIdeaViewModel.swift
//  AsaCrowdsource
//
//  アイデア作成を管理するViewModel
//

import Foundation
import SwiftUI
import SwiftData

/// アイデア作成ViewModel
@MainActor
@Observable
final class CreateIdeaViewModel {
    // MARK: - Properties

    var title: String = ""
    var ideaDescription: String = ""
    var category: IdeaCategory = .other
    private(set) var isLoading = false
    var errorMessage: String?

    // 編集モード用
    var isEditMode = false
    private var editingIdeaId: UUID?

    // MARK: - Private Properties

    private var dataService: LocalDataService?
    private var groupId: String?
    private var authorId: String?
    private var authorName: String?

    // MARK: - Computed Properties

    var isTitleValid: Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 100
    }

    var isDescriptionValid: Bool {
        ideaDescription.count <= 1000
    }

    var canSubmit: Bool {
        isTitleValid && isDescriptionValid
    }

    var titleCharacterCount: Int {
        title.count
    }

    var descriptionCharacterCount: Int {
        ideaDescription.count
    }

    var navigationTitle: String {
        isEditMode ? "アイデアを編集" : "新しいアイデア"
    }

    var submitButtonTitle: String {
        isEditMode ? "更新" : "投稿"
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

    /// 作成者情報を設定
    func setAuthor(id: String, name: String) {
        self.authorId = id
        self.authorName = name
    }

    /// 編集モードで初期化
    func setupForEditing(_ idea: Idea) {
        isEditMode = true
        editingIdeaId = idea.id
        title = idea.title
        ideaDescription = idea.ideaDescription
        category = idea.category
    }

    /// フォームをリセット
    func reset() {
        title = ""
        ideaDescription = ""
        category = .other
        isEditMode = false
        editingIdeaId = nil
        errorMessage = nil
    }

    /// アイデアを作成または更新
    func submit() async -> Idea? {
        guard canSubmit else {
            errorMessage = "入力内容を確認してください"
            return nil
        }

        guard let dataService = dataService,
              let groupId = groupId,
              let authorId = authorId,
              let authorName = authorName else {
            errorMessage = "設定エラーが発生しました"
            return nil
        }

        isLoading = true
        errorMessage = nil

        do {
            if isEditMode, let ideaId = editingIdeaId {
                // 編集モード：既存のアイデアを更新
                if let existingIdea = try await dataService.fetchIdea(id: ideaId) {
                    existingIdea.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    existingIdea.ideaDescription = ideaDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                    existingIdea.category = category
                    try await dataService.updateIdea(existingIdea)
                    isLoading = false
                    return existingIdea
                } else {
                    throw DataServiceError.ideaNotFound
                }
            } else {
                // 作成モード：新規アイデアを作成
                let idea = Idea(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    ideaDescription: ideaDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                    category: category,
                    authorId: authorId,
                    authorName: authorName,
                    groupId: groupId
                )
                let savedIdea = try await dataService.createIdea(idea)
                isLoading = false
                return savedIdea
            }
        } catch {
            errorMessage = "保存に失敗しました: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }

    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }
}
