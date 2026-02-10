import Foundation

// MARK: - ゲームモード

/// 4種類のゲームモードを定義
public enum GameMode: String, CaseIterable, Codable, Sendable {
    case mathQuiz = "mathQuiz"
    case hiraganaPractice = "hiraganaPractice"
    case shapePuzzle = "shapePuzzle"
    case logicGame = "logicGame"

    /// 表示名（子供向けひらがな）
    public var displayName: String {
        switch self {
        case .mathQuiz: return "さんすう"
        case .hiraganaPractice: return "ひらがな"
        case .shapePuzzle: return "かたち"
        case .logicGame: return "ろんり"
        }
    }

    /// モード別の絵文字アイコン
    public var emoji: String {
        switch self {
        case .mathQuiz: return "🔢"
        case .hiraganaPractice: return "🎌"
        case .shapePuzzle: return "🔷"
        case .logicGame: return "🧩"
        }
    }

    /// テーマカラー名（AsaUIKit連携用）
    public var themeColorName: String {
        switch self {
        case .mathQuiz: return "AsaCoffeeBrown"
        case .hiraganaPractice: return "AsaMocha"
        case .shapePuzzle: return "AsaMutedSage"
        case .logicGame: return "AsaDarkSlate"
        }
    }

    /// モードの説明文
    public var modeDescription: String {
        switch self {
        case .mathQuiz: return "たしざん・ひきざんにちょうせん！"
        case .hiraganaPractice: return "ひらがなをおぼえよう！"
        case .shapePuzzle: return "かたちをみつけよう！"
        case .logicGame: return "あたまのたいそう！"
        }
    }
}
