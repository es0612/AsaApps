import Foundation

// MARK: - 問題タイプ

/// ゲーム問題の詳細タイプ（13種類）
public enum QuestionType: String, CaseIterable, Codable, Sendable {
    // 算数系（4種）
    case addition = "addition"
    case subtraction = "subtraction"
    case comparison = "comparison"
    case fillInBlank = "fillInBlank"

    // ひらがな系（3種）
    case hiraganaReading = "hiraganaReading"
    case hiraganaMatching = "hiraganaMatching"
    case hiraganaWriting = "hiraganaWriting"

    // 図形系（3種）
    case shapeIdentification = "shapeIdentification"
    case shapePattern = "shapePattern"
    case shapeCombination = "shapeCombination"

    // 論理系（3種）
    case oddOneOut = "oddOneOut"
    case sequenceOrder = "sequenceOrder"
    case patternCompletion = "patternCompletion"

    /// この問題タイプが属するゲームモード
    public var gameMode: GameMode {
        switch self {
        case .addition, .subtraction, .comparison, .fillInBlank:
            return .mathQuiz
        case .hiraganaReading, .hiraganaMatching, .hiraganaWriting:
            return .hiraganaPractice
        case .shapeIdentification, .shapePattern, .shapeCombination:
            return .shapePuzzle
        case .oddOneOut, .sequenceOrder, .patternCompletion:
            return .logicGame
        }
    }

    /// 表示名
    public var displayName: String {
        switch self {
        case .addition: return "たしざん"
        case .subtraction: return "ひきざん"
        case .comparison: return "くらべっこ"
        case .fillInBlank: return "あなうめ"
        case .hiraganaReading: return "よみかた"
        case .hiraganaMatching: return "くみあわせ"
        case .hiraganaWriting: return "かきかた"
        case .shapeIdentification: return "なにのかたち？"
        case .shapePattern: return "パターン"
        case .shapeCombination: return "くみあわせ"
        case .oddOneOut: return "なかまはずれ"
        case .sequenceOrder: return "じゅんばん"
        case .patternCompletion: return "つぎはなに？"
        }
    }

    /// 対応する難易度レベル
    public var availableDifficulties: [DifficultyLevel] {
        switch self {
        case .addition, .subtraction, .hiraganaReading, .hiraganaMatching,
            .shapeIdentification, .oddOneOut:
            return DifficultyLevel.allCases
        case .comparison, .fillInBlank, .hiraganaWriting,
            .shapePattern, .shapeCombination, .sequenceOrder, .patternCompletion:
            return [.normal, .hard]
        }
    }
}
