import Foundation

// MARK: - ModerationResult

/// コンテンツモデレーション結果
public struct ModerationResult: Sendable {
    /// 全体の感情スコア（-1.0〜1.0、負=ネガティブ、正=ポジティブ）
    public let sentimentScore: Double
    /// 検出された言語コード
    public let detectedLanguage: String?
    /// 投稿を許可すべきか
    public let isAcceptable: Bool
    /// 警告メッセージ（問題がある場合）
    public let warningMessage: String?

    public init(
        sentimentScore: Double,
        detectedLanguage: String? = nil,
        isAcceptable: Bool = true,
        warningMessage: String? = nil
    ) {
        self.sentimentScore = sentimentScore
        self.detectedLanguage = detectedLanguage
        self.isAcceptable = isAcceptable
        self.warningMessage = warningMessage
    }
}

// MARK: - ContentModerating

/// 感情分析・コンテンツモデレーション抽象化プロトコル
public protocol ContentModerating: Sendable {
    /// テキストの感情分析を実行
    func analyzeSentiment(text: String) -> ModerationResult

    /// テキストの言語を検出
    func detectLanguage(text: String) -> String?
}
