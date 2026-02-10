import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 手書き認識サービス

/// Core ML ベースのひらがな手書き認識サービス（スタブ実装）
/// 実際のMLモデル統合は将来的に行う。現在はランダムベースのスタブ認識を提供。
public final class HandwritingRecognitionService: HandwritingRecognizing {

    // MARK: - Properties

    /// サポートするひらがな46文字（五十音順）
    private static let allHiragana: [String] = [
        "あ", "い", "う", "え", "お",
        "か", "き", "く", "け", "こ",
        "さ", "し", "す", "せ", "そ",
        "た", "ち", "つ", "て", "と",
        "な", "に", "ぬ", "ね", "の",
        "は", "ひ", "ふ", "へ", "ほ",
        "ま", "み", "む", "め", "も",
        "や", "ゆ", "よ",
        "ら", "り", "る", "れ", "ろ",
        "わ", "を", "ん",
    ]

    // MARK: - Init

    public init() {}

    // MARK: - HandwritingRecognizing

    /// 描画データからひらがなを認識（スタブ実装）
    /// 将来的にはCore MLモデルと連携して画像認識を行う
    public func recognize(
        drawingPoints: [[CGPoint]]
    ) async throws -> HandwritingResult {
        // ストロークが空の場合はエラー
        guard !drawingPoints.isEmpty,
              drawingPoints.contains(where: { !$0.isEmpty })
        else {
            throw EduGameError.handwritingRecognitionFailed("ストロークデータが空です")
        }

        // スタブ実装: ストローク数から推定（簡易ヒューリスティクス）
        let strokeCount = drawingPoints.count
        let character = estimateCharacter(fromStrokeCount: strokeCount)
        let confidence = estimateConfidence(drawingPoints: drawingPoints)

        // 候補リストの生成（メインの推定結果 + ランダムな候補2つ）
        var candidates: [(character: String, confidence: Double)] = [
            (character, confidence),
        ]
        var pool = Self.allHiragana.filter { $0 != character }
        pool.shuffle()
        for i in 0 ..< min(2, pool.count) {
            let candidateConfidence = max(0.1, confidence - Double(i + 1) * 0.2)
            candidates.append((pool[i], candidateConfidence))
        }

        return HandwritingResult(
            recognizedCharacter: character,
            confidence: confidence,
            candidates: candidates
        )
    }

    /// サポートされている文字セットを取得
    public func supportedCharacters() -> [String] {
        return Self.allHiragana
    }

    // MARK: - ヘルパー（スタブ用）

    /// ストローク数からひらがなを推定（簡易ヒューリスティクス）
    private func estimateCharacter(fromStrokeCount strokeCount: Int) -> String {
        // 画数に基づく大まかな分類（スタブ実装）
        switch strokeCount {
        case 1:
            // 1画: へ、く、し、つ、の、etc.
            return ["へ", "く", "し", "つ", "の"].randomElement()!
        case 2:
            // 2画: い、こ、り、う、か、etc.
            return ["い", "こ", "り", "う", "か"].randomElement()!
        case 3:
            // 3画: あ、お、き、け、た、etc.
            return ["あ", "お", "き", "け", "た"].randomElement()!
        case 4:
            // 4画: ね、は、ほ、む、etc.
            return ["ね", "は", "ほ", "む"].randomElement()!
        default:
            return Self.allHiragana.randomElement()!
        }
    }

    /// 描画データから信頼度を推定（スタブ実装）
    private func estimateConfidence(drawingPoints: [[CGPoint]]) -> Double {
        // 各ストロークのポイント数を合算
        let totalPoints = drawingPoints.reduce(0) { $0 + $1.count }

        // ポイント数が少なすぎると信頼度が低い
        if totalPoints < 5 {
            return 0.3
        } else if totalPoints < 20 {
            return 0.5
        } else if totalPoints < 50 {
            return 0.7
        } else {
            return 0.85
        }
    }
}
