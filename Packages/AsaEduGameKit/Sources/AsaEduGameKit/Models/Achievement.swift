import Foundation
import SwiftData
import SwiftUI
import AsaUIKit

// MARK: - アチーブメント

/// バッジ/実績データ
@Model
public final class Achievement {
    public var id: UUID = UUID()

    /// バッジID（一意識別子）
    public var badgeId: String = ""

    /// バッジタイトル
    public var title: String = ""

    /// バッジ説明
    public var achievementDescription: String = ""

    /// バッジ絵文字
    public var emoji: String = "⭐"

    /// 解除日時
    public var unlockedAt: Date = Date()

    /// 所属プロフィール
    public var profile: UserProfile?

    public init(
        badgeId: String = "",
        title: String = "",
        achievementDescription: String = "",
        emoji: String = "⭐"
    ) {
        self.badgeId = badgeId
        self.title = title
        self.achievementDescription = achievementDescription
        self.emoji = emoji
    }
}

// MARK: - バッジ定義

/// 利用可能な全バッジ（13種）
public enum BadgeDefinition: String, CaseIterable, Sendable {
    case firstStar = "first_star"
    case mathMaster = "math_master"
    case hiraganaHero = "hiragana_hero"
    case shapeExpert = "shape_expert"
    case logicGenius = "logic_genius"
    case combo5 = "combo_5"
    case superCombo = "super_combo"
    case perfect = "perfect"
    case dailyPlayer = "daily_player"
    case starCollector100 = "star_collector_100"
    case starCollector500 = "star_collector_500"
    case levelThree = "level_three"
    case allModes = "all_modes"

    /// バッジタイトル
    public var title: String {
        switch self {
        case .firstStar: return "はじめてのほし"
        case .mathMaster: return "さんすうマスター"
        case .hiraganaHero: return "ひらがなヒーロー"
        case .shapeExpert: return "かたちはかせ"
        case .logicGenius: return "ろんりてんさい"
        case .combo5: return "コンボ5!"
        case .superCombo: return "スーパーコンボ"
        case .perfect: return "パーフェクト"
        case .dailyPlayer: return "まいにちがんばる"
        case .starCollector100: return "ほしあつめ100"
        case .starCollector500: return "ほしあつめ500"
        case .levelThree: return "レベル3たっせい"
        case .allModes: return "ぜんぶやったよ"
        }
    }

    /// バッジ絵文字（後方互換／既存データ用）
    public var emoji: String {
        switch self {
        case .firstStar: return "⭐"
        case .mathMaster: return "🔢"
        case .hiraganaHero: return "🎌"
        case .shapeExpert: return "🔷"
        case .logicGenius: return "🧩"
        case .combo5: return "🔥"
        case .superCombo: return "💥"
        case .perfect: return "💯"
        case .dailyPlayer: return "📅"
        case .starCollector100: return "🌟"
        case .starCollector500: return "✨"
        case .levelThree: return "🏆"
        case .allModes: return "🎮"
        }
    }

    /// バッジの SF Symbol アイコン名
    public var systemImage: String {
        switch self {
        case .firstStar: return "star.fill"
        case .mathMaster: return "function"
        case .hiraganaHero: return "character.book.closed.fill"
        case .shapeExpert: return "square.on.circle.fill"
        case .logicGenius: return "puzzlepiece.fill"
        case .combo5: return "flame.fill"
        case .superCombo: return "bolt.fill"
        case .perfect: return "checkmark.seal.fill"
        case .dailyPlayer: return "calendar"
        case .starCollector100: return "sparkles"
        case .starCollector500: return "star.square.on.square.fill"
        case .levelThree: return "trophy.fill"
        case .allModes: return "gamecontroller.fill"
        }
    }

    /// バッジアイコン色（ブランドカラーから割当）
    public var iconColor: Color {
        switch self {
        case .firstStar, .mathMaster, .perfect, .levelThree:
            return AsaColors.coffeeBrown
        case .hiraganaHero, .shapeExpert, .combo5, .superCombo:
            return AsaColors.mocha
        case .logicGenius, .dailyPlayer, .allModes:
            return AsaColors.mutedSage
        case .starCollector100, .starCollector500:
            return AsaColors.coffeeBrown
        }
    }

    /// バッジ説明
    public var badgeDescription: String {
        switch self {
        case .firstStar: return "はじめてほしをゲット！"
        case .mathMaster: return "さんすうで50もんせいかい！"
        case .hiraganaHero: return "ひらがなで50もんせいかい！"
        case .shapeExpert: return "かたちで50もんせいかい！"
        case .logicGenius: return "ろんりで50もんせいかい！"
        case .combo5: return "5れんぞくせいかい！"
        case .superCombo: return "10れんぞくせいかい！"
        case .perfect: return "ぜんもんせいかい！"
        case .dailyPlayer: return "3にちれんぞくプレイ！"
        case .starCollector100: return "ほしを100こあつめた！"
        case .starCollector500: return "ほしを500こあつめた！"
        case .levelThree: return "レベル3にとうたつ！"
        case .allModes: return "4つのモードぜんぶやった！"
        }
    }
}
