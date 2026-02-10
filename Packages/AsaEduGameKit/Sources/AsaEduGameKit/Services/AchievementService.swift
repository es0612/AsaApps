import Foundation

// MARK: - アチーブメントサービス

/// バッジの解除条件を判定し、管理するサービス
/// 13種のバッジ定義に対応した条件チェックを提供
public final class AchievementService {

    // MARK: - Properties

    /// データサービスへの依存（@MainActor のためプロトコル経由で利用）
    private let dataService: any EduGameDataServiceProtocol

    // MARK: - Init

    public init(dataService: any EduGameDataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Methods

    /// セッション完了後にバッジの解除条件をチェックし、新規解除バッジを返す
    @MainActor
    public func checkAndUnlockAchievements(
        profile: UserProfile,
        session: GameSession
    ) throws -> [BadgeDefinition] {
        // 既に解除済みのバッジを取得
        let unlockedIds = try dataService.unlockedBadgeIds(for: profile)
        var newlyUnlocked: [BadgeDefinition] = []

        // 全バッジの条件をチェック
        for badge in BadgeDefinition.allCases {
            // 既に解除済みならスキップ
            guard !unlockedIds.contains(badge.rawValue) else { continue }

            // 条件判定
            let isUnlocked = try checkCondition(
                badge: badge,
                profile: profile,
                session: session
            )

            if isUnlocked {
                _ = try dataService.unlockAchievement(for: profile, badge: badge)
                newlyUnlocked.append(badge)
            }
        }

        return newlyUnlocked
    }

    // MARK: - 条件チェック

    /// 各バッジの解除条件を判定
    @MainActor
    private func checkCondition(
        badge: BadgeDefinition,
        profile: UserProfile,
        session: GameSession
    ) throws -> Bool {
        switch badge {
        case .firstStar:
            // はじめてのほし: 星を1つ以上獲得
            return profile.totalStars > 0 || session.earnedStars > 0

        case .mathMaster:
            // さんすうマスター: 算数で50問正解
            let count = try dataService.correctAnswerCount(for: profile, mode: .mathQuiz)
            return count >= 50

        case .hiraganaHero:
            // ひらがなヒーロー: ひらがなで50問正解
            let count = try dataService.correctAnswerCount(for: profile, mode: .hiraganaPractice)
            return count >= 50

        case .shapeExpert:
            // かたちはかせ: 図形で50問正解
            let count = try dataService.correctAnswerCount(for: profile, mode: .shapePuzzle)
            return count >= 50

        case .logicGenius:
            // ろんりてんさい: 論理で50問正解
            let count = try dataService.correctAnswerCount(for: profile, mode: .logicGame)
            return count >= 50

        case .combo5:
            // コンボ5: 5連続正解達成
            return session.maxCombo >= 5

        case .superCombo:
            // スーパーコンボ: 10連続正解達成
            return session.maxCombo >= 10

        case .perfect:
            // パーフェクト: 全問正解
            return session.isPerfect

        case .dailyPlayer:
            // まいにちがんばる: 3日連続プレイ
            let days = try dataService.consecutivePlayDays(for: profile)
            return days >= 3

        case .starCollector100:
            // ほしあつめ100: 累計100星
            return (profile.totalStars + session.earnedStars) >= 100

        case .starCollector500:
            // ほしあつめ500: 累計500星
            return (profile.totalStars + session.earnedStars) >= 500

        case .levelThree:
            // レベル3たっせい: レベル3に到達
            let totalStars = profile.totalStars + session.earnedStars
            let level = UserProfile.calculateLevel(from: totalStars)
            return level >= 3

        case .allModes:
            // ぜんぶやったよ: 4つのモード全てプレイ
            var modes = try dataService.playedModes(for: profile)
            modes.insert(session.gameMode)
            return modes.count >= GameMode.allCases.count
        }
    }
}
