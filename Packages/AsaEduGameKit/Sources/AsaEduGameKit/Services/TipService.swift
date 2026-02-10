import Foundation
import TipKit

// MARK: - ゲームモードTip

/// ゲームモード選択画面で表示するヒント
public struct GameModeTip: Tip {
    public var title: Text {
        Text("あそびかたをえらぼう！")
    }

    public var message: Text? {
        Text("さんすう・ひらがな・かたち・ろんり、すきなモードをタップしてね！")
    }

    public var image: Image? {
        Image(systemName: "gamecontroller.fill")
    }

    public init() {}
}

// MARK: - 初回プレイTip

/// 初回プレイ時に表示するヒント
public struct FirstPlayTip: Tip {
    /// 1回もプレイしていない場合に表示
    @Parameter
    public static var hasPlayedBefore: Bool = false

    public var rules: [Rule] {
        [
            #Rule(Self.$hasPlayedBefore) { $0 == false },
        ]
    }

    public var title: Text {
        Text("はじめてのチャレンジ！")
    }

    public var message: Text? {
        Text("もんだいがでたら、こたえをタップしよう。せいかいするとほしがもらえるよ！")
    }

    public var image: Image? {
        Image(systemName: "star.fill")
    }

    public init() {}
}

// MARK: - コンボTip

/// コンボ達成時に表示するヒント
public struct ComboTip: Tip {
    /// コンボ初達成フラグ
    @Parameter
    public static var hasSeenCombo: Bool = false

    public var rules: [Rule] {
        [
            #Rule(Self.$hasSeenCombo) { $0 == false },
        ]
    }

    public var title: Text {
        Text("コンボだ！")
    }

    public var message: Text? {
        Text("れんぞくせいかいするとコンボになるよ！コンボがつづくとボーナスほしがもらえる！")
    }

    public var image: Image? {
        Image(systemName: "flame.fill")
    }

    public init() {}
}

// MARK: - TipService

/// TipKitの初期化と管理を行うサービス
public final class TipService {

    // MARK: - Init

    public init() {}

    // MARK: - Methods

    /// TipKit の初期化（アプリ起動時に1回呼ぶ）
    public func configure() {
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault),
        ])
    }

    /// 初回プレイ完了を記録（Tipを非表示にする）
    public func markFirstPlayCompleted() {
        FirstPlayTip.hasPlayedBefore = true
    }

    /// コンボ初達成を記録（Tipを非表示にする）
    public func markComboSeen() {
        ComboTip.hasSeenCombo = true
    }

    /// 全てのTipをリセット（デバッグ用）
    public func resetAllTips() {
        try? Tips.resetDatastore()
    }
}
