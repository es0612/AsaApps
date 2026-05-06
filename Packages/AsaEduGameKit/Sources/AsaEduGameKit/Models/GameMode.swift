import Foundation
import SwiftUI
import AsaUIKit

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

    /// モード別の絵文字アイコン（後方互換／既存データ用）
    public var emoji: String {
        switch self {
        case .mathQuiz: return "🔢"
        case .hiraganaPractice: return "🎌"
        case .shapePuzzle: return "🔷"
        case .logicGame: return "🧩"
        }
    }

    /// モード別の SF Symbol アイコン名
    public var systemImage: String {
        switch self {
        case .mathQuiz: return "function"
        case .hiraganaPractice: return "character.book.closed.fill"
        case .shapePuzzle: return "square.on.circle.fill"
        case .logicGame: return "puzzlepiece.fill"
        }
    }

    /// テーマカラー（AsaUIKit のブランドカラーを返す）
    public var themeColor: Color {
        switch self {
        case .mathQuiz: return AsaColors.coffeeBrown
        case .hiraganaPractice: return AsaColors.mocha
        case .shapePuzzle: return AsaColors.mutedSage
        case .logicGame: return AsaColors.darkSlate
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
