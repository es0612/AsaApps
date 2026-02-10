import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 手書き認識プロトコル

/// 手書き認識結果
public struct HandwritingResult: Sendable {
    /// 認識された文字
    public let recognizedCharacter: String
    /// 信頼度（0.0〜1.0）
    public let confidence: Double
    /// 候補リスト（信頼度順）
    public let candidates: [(character: String, confidence: Double)]

    public init(
        recognizedCharacter: String,
        confidence: Double,
        candidates: [(character: String, confidence: Double)] = []
    ) {
        self.recognizedCharacter = recognizedCharacter
        self.confidence = confidence
        self.candidates = candidates
    }
}

/// ひらがな手書き認識サービスのインターフェース
public protocol HandwritingRecognizing: Sendable {
    /// 描画データからひらがなを認識
    func recognize(
        drawingPoints: [[CGPoint]]
    ) async throws -> HandwritingResult

    /// サポートされている文字セットを取得
    func supportedCharacters() -> [String]
}
