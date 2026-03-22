//
//  RecipeAIService.swift
//  AsaRecipeAI
//
//  Foundation Modelsを使用したAIレシピサービス
//  オンデバイスLLMで食材認識とレシピ生成
//

import Foundation
import FoundationModels

// MARK: - RecipeAIService

/// Foundation Models を使用したAIレシピサービス
@MainActor
@Observable
final class RecipeAIService {
    // MARK: - Properties

    /// LLMセッション
    private var session: LanguageModelSession?

    /// 処理中フラグ
    private(set) var isProcessing = false

    /// セッション準備完了フラグ
    private(set) var isSessionReady = false

    /// エラーメッセージ
    private(set) var lastError: String?

    // MARK: - Initialization

    init() {
        Task {
            await prepareSession()
        }
    }

    // MARK: - Public Methods

    /// セッションを準備（プレウォーム）
    func prepareSession() async {
        do {
            // デバイス互換性チェック
            guard case .available = SystemLanguageModel.default.availability else {
                lastError = "このデバイスではFoundation Modelsが利用できません"
                return
            }

            session = LanguageModelSession()
            try await session?.prewarm()
            isSessionReady = true
            lastError = nil
        } catch {
            lastError = "セッションの準備に失敗しました: \(error.localizedDescription)"
            isSessionReady = false
        }
    }

    /// Vision分類結果から食材を認識
    /// - Parameter visionLabels: Visionフレームワークからの分類ラベル
    /// - Returns: 食材認識結果
    func recognizeIngredients(from visionLabels: [String]) async throws -> IngredientRecognitionResult {
        guard let session else {
            throw RecipeAIError.sessionNotReady
        }

        isProcessing = true
        defer { isProcessing = false }

        let labelList = visionLabels.joined(separator: ", ")

        let prompt = """
        以下の画像分類結果から、料理に使える食材を特定してください。

        分類結果: \(labelList)

        注意事項:
        - 日本語で食材名を出力してください
        - カテゴリは「野菜、肉類、魚介類、乳製品、穀物、調味料、卵、豆腐・大豆製品、果物、その他」のいずれかを使用
        - 各食材に適切な絵文字を1つ付けてください
        - 信頼度は0.0〜1.0の範囲で設定してください
        - 食材として認識できるものだけを抽出してください
        """

        let response = try await session.respond(
            to: prompt,
            generating: IngredientRecognitionResult.self
        )

        return response.content
    }

    /// 食材からレシピを推薦（非ストリーミング）
    /// - Parameters:
    ///   - ingredients: 認識された食材
    ///   - preferences: ユーザー設定
    /// - Returns: レシピ推薦リスト
    func recommendRecipes(
        for ingredients: [IngredientInfo],
        preferences: UserPreferences?
    ) async throws -> RecipeRecommendations {
        guard let session else {
            throw RecipeAIError.sessionNotReady
        }

        isProcessing = true
        defer { isProcessing = false }

        let prompt = buildRecipePrompt(ingredients: ingredients, preferences: preferences)

        let response = try await session.respond(
            to: prompt,
            generating: RecipeRecommendations.self
        )

        return response.content
    }

    /// 食材からレシピを推薦（ストリーミング）
    /// - Parameters:
    ///   - ingredients: 認識された食材
    ///   - preferences: ユーザー設定
    /// - Returns: ストリーミングレスポンス
    func streamRecipeRecommendations(
        for ingredients: [IngredientInfo],
        preferences: UserPreferences?
    ) -> AsyncThrowingStream<RecipeRecommendations.PartiallyGenerated, Error> {
        AsyncThrowingStream { continuation in
            Task { @MainActor in
                guard let session = self.session else {
                    continuation.finish(throwing: RecipeAIError.sessionNotReady)
                    return
                }

                self.isProcessing = true

                let prompt = self.buildRecipePrompt(ingredients: ingredients, preferences: preferences)

                do {
                    for try await partial in session.streamResponse(
                        to: prompt,
                        generating: RecipeRecommendations.self
                    ) {
                        continuation.yield(partial.content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }

                self.isProcessing = false
            }
        }
    }

    // MARK: - Private Methods

    /// レシピ推薦用のプロンプトを構築
    private func buildRecipePrompt(
        ingredients: [IngredientInfo],
        preferences: UserPreferences?
    ) -> String {
        let ingredientList = ingredients.map { "\($0.emoji) \($0.name)" }.joined(separator: ", ")
        let maxTime = preferences?.maxCookingTime ?? 60
        let servings = preferences?.defaultServings ?? 2
        let recipeCount = preferences?.recipeCount ?? 3

        var prompt = """
        以下の食材を使ったレシピを\(recipeCount)つ提案してください。

        利用可能な食材: \(ingredientList)
        最大調理時間: \(maxTime)分
        人数: \(servings)人分
        """

        // 食事制限があれば追加
        if let restriction = preferences?.dietaryRestriction, restriction != .none {
            prompt += "\n食事制限: \(restriction.description)"
        }

        // 除外食材があれば追加
        if let excluded = preferences?.excludedIngredients, !excluded.isEmpty {
            prompt += "\n使用しない食材: \(excluded.joined(separator: ", "))"
        }

        prompt += """


        提案の注意事項:
        - 家庭料理として作りやすいレシピを提案してください
        - 各レシピには詳細な調理手順を含めてください
        - 利用可能な食材は isAvailable を true にしてください
        - 追加で必要な食材は isAvailable を false にしてください
        - 推薦理由を簡潔に説明してください
        - 難易度は「簡単」「普通」「上級」のいずれかで設定してください
        """

        return prompt
    }
}

// MARK: - RecipeAIError

/// RecipeAIServiceのエラー
enum RecipeAIError: Error, LocalizedError {
    case sessionNotReady
    case deviceNotSupported
    case generationFailed(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .sessionNotReady:
            return "AIセッションが準備できていません"
        case .deviceNotSupported:
            return "このデバイスではAI機能を利用できません"
        case .generationFailed(let message):
            return "レシピ生成に失敗しました: \(message)"
        case .invalidResponse:
            return "無効な応答を受信しました"
        }
    }
}
