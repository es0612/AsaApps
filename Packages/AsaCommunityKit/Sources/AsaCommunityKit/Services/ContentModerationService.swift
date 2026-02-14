import Foundation
import NaturalLanguage

// MARK: - ContentModerationService

/// NaturalLanguageフレームワークによるコンテンツモデレーションサービス
public struct ContentModerationService: ContentModerating {

    /// ネガティブ判定の閾値（この値以下で不適切と判定）
    private let negativeThreshold: Double

    public init(negativeThreshold: Double = -0.5) {
        self.negativeThreshold = negativeThreshold
    }

    // MARK: - ContentModerating

    public func analyzeSentiment(text: String) -> ModerationResult {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        // 感情スコアを取得（-1.0〜1.0）
        let (tag, _) = tagger.tag(
            at: text.startIndex,
            unit: .paragraph,
            scheme: .sentimentScore
        )

        let score = Double(tag?.rawValue ?? "0") ?? 0.0
        let language = detectLanguage(text: text)

        if score < negativeThreshold {
            return ModerationResult(
                sentimentScore: score,
                detectedLanguage: language,
                isAcceptable: false,
                warningMessage: "投稿内容にネガティブな表現が含まれています。コミュニティガイドラインに沿った表現への修正をお願いします。"
            )
        }

        return ModerationResult(
            sentimentScore: score,
            detectedLanguage: language,
            isAcceptable: true,
            warningMessage: nil
        )
    }

    public func detectLanguage(text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }
}
