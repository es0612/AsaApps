import Foundation

// MARK: - GameState
/// ゲームの状態を管理する列挙型
enum GameState: Sendable, Equatable {
    /// 初期状態（起動直後）
    case idle
    /// 平面検出待ち
    case waitingForPlane
    /// ゲーム開始準備完了
    case ready
    /// ゲームプレイ中
    case playing
    /// 一時停止中
    case paused
    /// ゲーム終了
    case gameOver

    // MARK: - Computed Properties

    /// ゲームが開始可能かどうか
    var canStartGame: Bool {
        self == .ready || self == .gameOver
    }

    /// ゲームが進行中かどうか
    var isGameActive: Bool {
        self == .playing
    }

    /// HUDを表示するかどうか
    var shouldShowHUD: Bool {
        self == .playing || self == .paused
    }

    /// 日本語表示用の説明
    var description: String {
        switch self {
        case .idle:
            return "初期化中"
        case .waitingForPlane:
            return "平面を検出中..."
        case .ready:
            return "準備完了"
        case .playing:
            return "プレイ中"
        case .paused:
            return "一時停止"
        case .gameOver:
            return "ゲーム終了"
        }
    }
}
