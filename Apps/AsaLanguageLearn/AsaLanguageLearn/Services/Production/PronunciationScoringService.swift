//
//  PronunciationScoringService.swift
//  AsaLanguageLearn
//
//  発音スコアリングサービスの実装
//

import Foundation

/// 発音スコアリングサービス
/// Levenshtein距離ベースの類似度計算
final class PronunciationScoringService: PronunciationScoringServiceProtocol, Sendable {
    // MARK: - Singleton

    static let shared = PronunciationScoringService()

    private init() {}

    // MARK: - Public Methods

    func calculateScore(recognized: String, target: String) -> PronunciationResult {
        // テキストの正規化
        let normalizedRecognized = normalize(recognized)
        let normalizedTarget = normalize(target)

        // 単語に分割
        let recognizedWords = normalizedRecognized.split(separator: " ").map(String.init)
        let targetWords = normalizedTarget.split(separator: " ").map(String.init)

        // 単語ごとのマッチング
        let wordMatches = calculateWordMatches(
            recognized: recognizedWords,
            target: targetWords
        )

        // スコア計算
        let score = calculateOverallScore(
            normalizedRecognized: normalizedRecognized,
            normalizedTarget: normalizedTarget,
            wordMatches: wordMatches
        )

        return PronunciationResult(
            score: score,
            accuracy: PronunciationAccuracy.from(score: score),
            normalizedRecognized: normalizedRecognized,
            normalizedTarget: normalizedTarget,
            wordMatches: wordMatches
        )
    }

    // MARK: - Private Methods

    /// テキストを正規化
    private func normalize(_ text: String) -> String {
        text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            // 句読点を削除
            .replacingOccurrences(of: "[.,!?;:'\"\\-]", with: "", options: .regularExpression)
            // 連続する空白を1つに
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    /// 単語ごとのマッチングを計算
    private func calculateWordMatches(
        recognized: [String],
        target: [String]
    ) -> [WordMatch] {
        var matches: [WordMatch] = []
        var recognizedIndex = 0

        for targetWord in target {
            var bestMatch: (index: Int, similarity: Double)? = nil

            // 残りの認識単語から最も類似した単語を探す
            for i in recognizedIndex..<recognized.count {
                let similarity = calculateWordSimilarity(
                    word1: recognized[i],
                    word2: targetWord
                )
                if similarity > 0.5 {
                    if bestMatch == nil || similarity > bestMatch!.similarity {
                        bestMatch = (i, similarity)
                    }
                }
            }

            if let match = bestMatch {
                // マッチが見つかった
                let isExactMatch = match.similarity >= 0.8
                matches.append(WordMatch(
                    targetWord: targetWord,
                    recognizedWord: recognized[match.index],
                    isMatch: isExactMatch
                ))
                recognizedIndex = match.index + 1
            } else {
                // マッチが見つからなかった
                matches.append(WordMatch(
                    targetWord: targetWord,
                    recognizedWord: nil,
                    isMatch: false
                ))
            }
        }

        return matches
    }

    /// 単語の類似度を計算（0.0〜1.0）
    private func calculateWordSimilarity(word1: String, word2: String) -> Double {
        if word1 == word2 { return 1.0 }

        let distance = levenshteinDistance(word1, word2)
        let maxLength = max(word1.count, word2.count)

        guard maxLength > 0 else { return 0.0 }

        return 1.0 - (Double(distance) / Double(maxLength))
    }

    /// 全体スコアを計算
    private func calculateOverallScore(
        normalizedRecognized: String,
        normalizedTarget: String,
        wordMatches: [WordMatch]
    ) -> Double {
        // 空文字列のチェック
        if normalizedTarget.isEmpty {
            return normalizedRecognized.isEmpty ? 1.0 : 0.0
        }

        if normalizedRecognized.isEmpty {
            return 0.0
        }

        // 方法1: 単語マッチ率
        let matchedCount = wordMatches.filter { $0.isMatch }.count
        let wordMatchScore = Double(matchedCount) / Double(wordMatches.count)

        // 方法2: 文字列類似度（Levenshtein）
        let distance = levenshteinDistance(normalizedRecognized, normalizedTarget)
        let maxLength = max(normalizedRecognized.count, normalizedTarget.count)
        let stringSimilarity = 1.0 - (Double(distance) / Double(maxLength))

        // 両方の方法を組み合わせる（重み付け）
        // 単語マッチ: 60%, 文字列類似度: 40%
        return wordMatchScore * 0.6 + stringSimilarity * 0.4
    }

    /// Levenshtein距離を計算
    /// 2つの文字列間の編集距離（挿入・削除・置換の最小回数）
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)

        let m = s1Array.count
        let n = s2Array.count

        // 空文字列のケース
        if m == 0 { return n }
        if n == 0 { return m }

        // DPテーブル
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        // 初期化
        for i in 0...m {
            dp[i][0] = i
        }
        for j in 0...n {
            dp[0][j] = j
        }

        // DPで距離を計算
        for i in 1...m {
            for j in 1...n {
                if s1Array[i - 1] == s2Array[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1]
                } else {
                    dp[i][j] = min(
                        dp[i - 1][j] + 1,      // 削除
                        dp[i][j - 1] + 1,      // 挿入
                        dp[i - 1][j - 1] + 1   // 置換
                    )
                }
            }
        }

        return dp[m][n]
    }
}
