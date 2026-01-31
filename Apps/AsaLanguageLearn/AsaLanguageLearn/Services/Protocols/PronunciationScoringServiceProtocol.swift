//
//  PronunciationScoringServiceProtocol.swift
//  AsaLanguageLearn
//
//  発音スコアリングサービスのプロトコル定義
//

import Foundation

/// 発音スコアリングサービスのプロトコル
protocol PronunciationScoringServiceProtocol: Sendable {
    /// 発音スコアを計算
    /// - Parameters:
    ///   - recognized: 認識されたテキスト
    ///   - target: ターゲットテキスト（正解）
    /// - Returns: スコアリング結果
    func calculateScore(recognized: String, target: String) -> PronunciationResult
}

/// 発音スコアリング結果
struct PronunciationResult: Sendable, Equatable {
    /// スコア（0.0〜1.0）
    let score: Double

    /// 精度レベル
    let accuracy: PronunciationAccuracy

    /// 認識されたテキスト（正規化済み）
    let normalizedRecognized: String

    /// ターゲットテキスト（正規化済み）
    let normalizedTarget: String

    /// 単語ごとのマッチ結果
    let wordMatches: [WordMatch]

    /// フィードバックメッセージ
    var feedbackMessage: String {
        accuracy.feedbackMessage
    }

    /// 正解としてカウントするか
    var countsAsCorrect: Bool {
        accuracy.countsAsCorrect
    }
}

/// 単語マッチ結果
struct WordMatch: Sendable, Equatable, Identifiable {
    let id: UUID
    let targetWord: String
    let recognizedWord: String?
    let isMatch: Bool

    init(
        id: UUID = UUID(),
        targetWord: String,
        recognizedWord: String?,
        isMatch: Bool
    ) {
        self.id = id
        self.targetWord = targetWord
        self.recognizedWord = recognizedWord
        self.isMatch = isMatch
    }
}
