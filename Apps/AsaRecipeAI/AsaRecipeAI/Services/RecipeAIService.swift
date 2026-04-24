//
//  RecipeAIService.swift
//  AsaRecipeAI
//
//  Foundation Modelsを使用したAIレシピサービス
//  オンデバイスLLMで食材認識とレシピ生成
//

import Foundation
import FoundationModels

// MARK: - RecipeAIServiceMode

/// サービスの動作モード
/// Foundation Models が使えない環境（シミュレータ、Apple Intelligence 非対応端末等）では
/// `.mock` に劣化してデモデータを返す
enum RecipeAIServiceMode: Equatable {
    /// Foundation Models で本物の推論を実行
    case live
    /// モック（シミュレータ／モデル未対応／準備失敗時）
    case mock(reason: String)

    var isLive: Bool {
        if case .live = self { return true }
        return false
    }

    /// UI に表示する文字列
    var userFacingLabel: String {
        switch self {
        case .live: return "AI準備完了"
        case .mock: return "デモモード"
        }
    }
}

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

    /// 動作モード（live / mock）
    private(set) var mode: RecipeAIServiceMode = .mock(reason: "初期化中")

    /// エラーメッセージ
    private(set) var lastError: String?

    /// セッション準備完了フラグ（mock モードでも UI 操作を許可するため、初期化中以外は true）
    var isSessionReady: Bool {
        if case .mock(let reason) = mode, reason == "初期化中" {
            return false
        }
        return true
    }

    // MARK: - Initialization

    init() {
        Task {
            await prepareSession()
        }
    }

    // MARK: - Public Methods

    /// セッションを準備（プレウォーム）
    /// availability チェックに一本化。Apple Intelligence 対応環境（シミュレータ含む）では本物の Foundation Models が動作する。
    /// 非対応環境では mock モードに劣化フォールバック。
    func prepareSession() async {
        // availability の詳細ケース分岐
        switch SystemLanguageModel.default.availability {
        case .available:
            break
        case .unavailable(let reason):
            mode = .mock(reason: Self.describe(reason))
            lastError = nil
            return
        @unknown default:
            mode = .mock(reason: "未対応の availability 状態")
            lastError = nil
            return
        }

        // セッション生成と prewarm を try/catch で包む
        do {
            let newSession = LanguageModelSession()
            try await newSession.prewarm()
            session = newSession
            mode = .live
            lastError = nil
        } catch {
            // prewarm 失敗時はモック経路に劣化
            session = nil
            mode = .mock(reason: "Foundation Models 初期化失敗: \(error.localizedDescription)")
            lastError = nil
        }
    }

    /// availability の理由を人間可読文字列に変換
    private static func describe(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "このデバイスは Apple Intelligence 非対応です"
        case .appleIntelligenceNotEnabled:
            return "設定で Apple Intelligence を有効にしてください"
        case .modelNotReady:
            return "モデルアセットをダウンロード中です"
        @unknown default:
            return "Foundation Models を利用できません"
        }
    }

    /// Vision分類結果から食材を認識
    /// - Parameter visionLabels: Visionフレームワークからの分類ラベル
    /// - Returns: 食材認識結果
    func recognizeIngredients(from visionLabels: [String]) async throws -> IngredientRecognitionResult {
        isProcessing = true
        defer { isProcessing = false }

        // モックモードなら Vision ラベルを参照せずデモデータを返す
        if case .mock = mode {
            try? await Task.sleep(nanoseconds: 600_000_000) // 演出用の軽い遅延
            return MockRecipeAIData.ingredientRecognition()
        }

        // live モードでも Vision ラベルが空の場合（シミュレータで Vision が使えない等）は
        // モック食材にフォールバック。空プロンプトで Foundation Models を呼ぶと結果が不安定になるため。
        if visionLabels.isEmpty {
            try? await Task.sleep(nanoseconds: 400_000_000)
            return MockRecipeAIData.ingredientRecognition()
        }

        guard let session else {
            // live のはずだがセッション喪失時はモックに劣化させて継続
            mode = .mock(reason: "セッション喪失")
            return MockRecipeAIData.ingredientRecognition()
        }

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

        do {
            let response = try await session.respond(
                to: prompt,
                generating: IngredientRecognitionResult.self
            )
            return response.content
        } catch {
            // 推論中に初めて低レベル例外が顕在化する場合も劣化フォールバック
            mode = .mock(reason: "推論失敗: \(error.localizedDescription)")
            return MockRecipeAIData.ingredientRecognition()
        }
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
        isProcessing = true
        defer { isProcessing = false }

        // モックモードならデモレシピを返す
        if case .mock = mode {
            try? await Task.sleep(nanoseconds: 800_000_000) // 演出用の軽い遅延
            return MockRecipeAIData.recommendations()
        }

        guard let session else {
            mode = .mock(reason: "セッション喪失")
            return MockRecipeAIData.recommendations()
        }

        let prompt = buildRecipePrompt(ingredients: ingredients, preferences: preferences)

        do {
            let response = try await session.respond(
                to: prompt,
                generating: RecipeRecommendations.self
            )
            return response.content
        } catch {
            mode = .mock(reason: "推論失敗: \(error.localizedDescription)")
            return MockRecipeAIData.recommendations()
        }
    }

    /// 食材からレシピを推薦（ストリーミング）
    /// - Parameters:
    ///   - ingredients: 認識された食材
    ///   - preferences: ユーザー設定
    /// - Returns: ストリーミングレスポンス
    /// - Note: mock モードでは即 sessionNotReady を投げ、ViewModel 側で非ストリーミング版にフォールバックさせる
    func streamRecipeRecommendations(
        for ingredients: [IngredientInfo],
        preferences: UserPreferences?
    ) -> AsyncThrowingStream<RecipeRecommendations.PartiallyGenerated, Error> {
        AsyncThrowingStream { continuation in
            Task { @MainActor in
                // mock モードならストリーミング非対応の信号を返し、ViewModel に sync 経路を使わせる
                if case .mock = self.mode {
                    continuation.finish(throwing: RecipeAIError.sessionNotReady)
                    return
                }

                guard let session = self.session else {
                    self.mode = .mock(reason: "セッション喪失")
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
                    // 推論中の失敗は mock に劣化させて ViewModel にフォールバックさせる
                    self.mode = .mock(reason: "推論失敗: \(error.localizedDescription)")
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
