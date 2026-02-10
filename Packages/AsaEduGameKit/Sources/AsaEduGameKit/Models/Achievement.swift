import Foundation
import SwiftData

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

    /// バッジ絵文字
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
