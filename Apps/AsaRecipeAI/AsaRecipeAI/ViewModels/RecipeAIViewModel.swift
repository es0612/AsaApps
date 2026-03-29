//
//  RecipeAIViewModel.swift
//  AsaRecipeAI
//
//  メインViewModel - 食材認識とレシピ生成を統括
//  Foundation Models + Vision の連携処理
//

import Foundation
import SwiftUI
import FoundationModels

// MARK: - RecipeAIViewModel

/// AsaRecipeAI のメインViewModel
@MainActor
@Observable
final class RecipeAIViewModel {
    // MARK: - Services

    private let recipeAIService: RecipeAIService
    private let visionService: VisionService
    private let dataService: DataService

    // MARK: - State Properties

    /// アプリ状態
    private(set) var appState: AppState = .idle

    /// 選択された画像
    private(set) var selectedImage: UIImage?

    /// 画像分析中フラグ
    private(set) var isAnalyzing = false

    /// レシピ生成中フラグ
    private(set) var isGeneratingRecipes = false

    /// AIセッション準備完了
    var isAIReady: Bool {
        recipeAIService.isSessionReady
    }

    // MARK: - Recognition Results

    /// 認識された食材
    private(set) var recognizedIngredients: [IngredientInfo] = []

    /// Vision分類結果（デバッグ用）
    private(set) var visionLabels: [String] = []

    // MARK: - Recipe Results

    /// ストリーミング中の部分レシピ
    private(set) var partialRecipes: RecipeRecommendations.PartiallyGenerated?

    /// 完成したレシピリスト
    private(set) var completedRecipes: [RecipeRecommendation] = []

    // MARK: - Data

    /// お気に入りレシピ
    private(set) var favoriteRecipes: [Recipe] = []

    /// 認識履歴
    private(set) var recognitionHistory: [RecognitionHistory] = []

    /// ユーザー設定
    private(set) var userPreferences: UserPreferences?

    /// 統計情報
    private(set) var statistics: AppStatistics?

    // MARK: - Error

    /// エラーメッセージ
    private(set) var errorMessage: String?

    /// エラー表示フラグ
    var showError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    // MARK: - Initialization

    init(
        recipeAIService: RecipeAIService,
        visionService: VisionService,
        dataService: DataService
    ) {
        self.recipeAIService = recipeAIService
        self.visionService = visionService
        self.dataService = dataService

        Task {
            await loadInitialData()
        }
    }

    // MARK: - Public Methods - Image Analysis

    /// 画像を選択
    func selectImage(_ image: UIImage) {
        selectedImage = image
        appState = .imageSelected
        clearResults()
    }

    /// 画像をクリア
    func clearImage() {
        selectedImage = nil
        appState = .idle
        clearResults()
    }

    /// 選択した画像を分析
    func analyzeSelectedImage() async {
        guard let image = selectedImage else {
            errorMessage = "画像が選択されていません"
            return
        }

        await analyzeImage(image)
    }

    /// 画像を分析して食材を認識
    func analyzeImage(_ image: UIImage) async {
        isAnalyzing = true
        appState = .analyzing
        errorMessage = nil
        clearResults()

        do {
            // Step 1: Vision で画像を分類
            let labels = try await visionService.extractFoodLabels(image)
            visionLabels = labels

            guard !labels.isEmpty else {
                throw RecipeAIError.generationFailed("食品が認識できませんでした")
            }

            // Step 2: Foundation Models で食材を特定
            let result = try await recipeAIService.recognizeIngredients(from: labels)
            recognizedIngredients = result.ingredients

            // Step 3: 履歴に保存（設定で有効な場合）
            let preferences = dataService.fetchUserPreferences()
            if preferences.autoSaveHistory {
                let thumbnail = visionService.generateThumbnail(image)
                _ = dataService.saveHistoryFromResult(result, thumbnailData: thumbnail)
                await refreshHistory()
            }

            appState = .ingredientsRecognized

        } catch {
            errorMessage = error.localizedDescription
            appState = .error(error.localizedDescription)
        }

        isAnalyzing = false
    }

    // MARK: - Public Methods - Recipe Generation

    /// レシピを生成（ストリーミング）
    func generateRecipes() async {
        guard !recognizedIngredients.isEmpty else {
            errorMessage = "食材が認識されていません"
            return
        }

        isGeneratingRecipes = true
        appState = .generatingRecipes
        partialRecipes = nil
        completedRecipes = []

        let preferences = dataService.fetchUserPreferences()

        do {
            for try await partial in recipeAIService.streamRecipeRecommendations(
                for: recognizedIngredients,
                preferences: preferences
            ) {
                partialRecipes = partial
            }

            // ストリーミング完了後、完成レシピを抽出
            if let finalRecipes = partialRecipes?.recipes {
                completedRecipes = finalRecipes.compactMap { partial in
                    guard let name = partial.name,
                          let description = partial.description,
                          let difficulty = partial.difficulty,
                          let cookingTimeMinutes = partial.cookingTimeMinutes,
                          let servings = partial.servings,
                          let recommendationReason = partial.recommendationReason else {
                        return nil
                    }
                    let ingredients = (partial.ingredients ?? []).compactMap { ing -> RecipeIngredient? in
                        guard let name = ing.name, let amount = ing.amount else { return nil }
                        return RecipeIngredient(name: name, amount: amount, isAvailable: ing.isAvailable ?? false)
                    }
                    let steps = (partial.steps ?? []).compactMap { step -> CookingStep? in
                        guard let stepNumber = step.stepNumber, let instruction = step.instruction else { return nil }
                        return CookingStep(stepNumber: stepNumber, instruction: instruction, tip: step.tip ?? nil)
                    }
                    return RecipeRecommendation(
                        name: name, description: description, difficulty: difficulty,
                        cookingTimeMinutes: cookingTimeMinutes, servings: servings,
                        ingredients: ingredients, steps: steps,
                        recommendationReason: recommendationReason
                    )
                }
            }

            appState = .recipesGenerated

        } catch {
            errorMessage = error.localizedDescription
            appState = .error(error.localizedDescription)
        }

        isGeneratingRecipes = false
    }

    /// レシピを生成（非ストリーミング）
    func generateRecipesSync() async {
        guard !recognizedIngredients.isEmpty else {
            errorMessage = "食材が認識されていません"
            return
        }

        isGeneratingRecipes = true
        appState = .generatingRecipes

        let preferences = dataService.fetchUserPreferences()

        do {
            let result = try await recipeAIService.recommendRecipes(
                for: recognizedIngredients,
                preferences: preferences
            )
            completedRecipes = result.recipes
            appState = .recipesGenerated

        } catch {
            errorMessage = error.localizedDescription
            appState = .error(error.localizedDescription)
        }

        isGeneratingRecipes = false
    }

    // MARK: - Public Methods - Data Management

    /// お気に入りにレシピを追加
    func addToFavorites(_ recommendation: RecipeRecommendation) {
        let recipe = dataService.saveRecipeFromRecommendation(recommendation, isFavorite: true)
        favoriteRecipes.insert(recipe, at: 0)
    }

    /// レシピをお気に入りから削除
    func removeFromFavorites(_ recipe: Recipe) {
        recipe.isFavorite = false
        dataService.savePreferences(userPreferences ?? UserPreferences())
        favoriteRecipes.removeAll { $0.id == recipe.id }
    }

    /// レシピを調理済みにマーク
    func markAsCooked(_ recipe: Recipe) {
        recipe.markAsCooked()
        dataService.savePreferences(userPreferences ?? UserPreferences())
    }

    /// 履歴を削除
    func deleteHistory(_ history: RecognitionHistory) {
        dataService.deleteHistory(history)
        recognitionHistory.removeAll { $0.id == history.id }
    }

    /// すべての履歴を削除
    func clearAllHistory() {
        dataService.clearAllHistory()
        recognitionHistory = []
    }

    /// データをリフレッシュ
    func refreshData() async {
        await loadInitialData()
    }

    /// お気に入りをリフレッシュ
    func refreshFavorites() async {
        favoriteRecipes = dataService.fetchFavoriteRecipes()
    }

    /// 履歴をリフレッシュ
    func refreshHistory() async {
        recognitionHistory = dataService.fetchRecentHistory()
    }

    /// 設定を更新
    func updatePreferences(_ preferences: UserPreferences) {
        dataService.savePreferences(preferences)
        userPreferences = preferences
    }

    // MARK: - Private Methods

    /// 初期データを読み込み
    private func loadInitialData() async {
        // 初回起動時のサンプルデータ投入
        let existingRecipes = dataService.fetchAllRecipes()
        let existingHistory = dataService.fetchAllHistory()
        if existingRecipes.isEmpty && existingHistory.isEmpty {
            let generator = SampleDataGenerator(dataService: dataService)
            generator.insertSampleData()
        }

        favoriteRecipes = dataService.fetchFavoriteRecipes()
        recognitionHistory = dataService.fetchRecentHistory()
        userPreferences = dataService.fetchUserPreferences()
        statistics = dataService.fetchStatistics()
    }

    /// 結果をクリア
    private func clearResults() {
        recognizedIngredients = []
        visionLabels = []
        partialRecipes = nil
        completedRecipes = []
        errorMessage = nil
    }
}

// MARK: - AppState

extension RecipeAIViewModel {
    /// アプリの状態
    enum AppState: Equatable {
        case idle
        case imageSelected
        case analyzing
        case ingredientsRecognized
        case generatingRecipes
        case recipesGenerated
        case error(String)

        var description: String {
            switch self {
            case .idle: return "画像を選択してください"
            case .imageSelected: return "画像が選択されました"
            case .analyzing: return "食材を認識中..."
            case .ingredientsRecognized: return "食材を認識しました"
            case .generatingRecipes: return "レシピを生成中..."
            case .recipesGenerated: return "レシピが生成されました"
            case .error(let message): return "エラー: \(message)"
            }
        }

        var canAnalyze: Bool {
            switch self {
            case .imageSelected, .error: return true
            default: return false
            }
        }

        var canGenerateRecipes: Bool {
            switch self {
            case .ingredientsRecognized, .recipesGenerated: return true
            default: return false
            }
        }
    }
}
