import Foundation
import SwiftData

// MARK: - ユーザープロフィール

/// 子供のプロフィール情報と学習進捗を管理
@Model
public final class UserProfile {
    public var id: UUID = UUID()

    /// 名前
    public var name: String = ""

    /// アバター絵文字
    public var avatarEmoji: String = "🐱"

    /// 年齢
    public var age: Int = 5

    /// 獲得した星の総数
    public var totalStars: Int = 0

    /// 現在のレベル（1-7）
    public var currentLevel: Int = 1

    /// 作成日時
    public var createdAt: Date = Date()

    /// 更新日時
    public var updatedAt: Date = Date()

    /// 関連ゲームセッション
    @Relationship(deleteRule: .cascade)
    public var sessions: [GameSession] = []

    /// 獲得したアチーブメント
    @Relationship(deleteRule: .cascade)
    public var achievements: [Achievement] = []

    public init(
        name: String = "",
        avatarEmoji: String = "🐱",
        age: Int = 5
    ) {
        self.name = name
        self.avatarEmoji = avatarEmoji
        self.age = age
    }

    // MARK: - レベル計算

    /// 星の総数からレベルを計算して更新
    public func updateLevel() {
        currentLevel = Self.calculateLevel(from: totalStars)
        updatedAt = Date()
    }

    /// 星数からレベルを算出（7段階）
    public static func calculateLevel(from stars: Int) -> Int {
        switch stars {
        case 0 ..< 50: return 1
        case 50 ..< 150: return 2
        case 150 ..< 300: return 3
        case 300 ..< 500: return 4
        case 500 ..< 750: return 5
        case 750 ..< 1000: return 6
        default: return 7
        }
    }

    /// 次のレベルまでに必要な星数
    public var starsToNextLevel: Int {
        let thresholds = [0, 50, 150, 300, 500, 750, 1000]
        guard currentLevel < 7 else { return 0 }
        return thresholds[currentLevel] - totalStars
    }

    /// レベルの表示名
    public var levelDisplayName: String {
        let names = ["", "ビギナー", "チャレンジャー", "がんばりや", "エキスパート", "マスター", "チャンピオン", "レジェンド"]
        return names[currentLevel]
    }
}
