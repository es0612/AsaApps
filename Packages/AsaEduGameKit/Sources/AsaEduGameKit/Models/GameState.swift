import Foundation

// MARK: - ゲーム状態

/// ゲームプレイの状態遷移を管理
public enum EduGameState: String, Sendable {
    /// 待機中（ゲーム未開始）
    case idle
    /// プレイ中（問題表示）
    case playing
    /// 回答中（ユーザー入力待ち）
    case answering
    /// 結果表示中（正解/不正解フィードバック）
    case showingResult
    /// お祝いアニメーション中（コンボ・パーフェクト等）
    case celebration
    /// セッション完了（結果画面表示）
    case sessionComplete

    /// 状態の表示名
    public var displayName: String {
        switch self {
        case .idle: return "スタンバイ"
        case .playing: return "もんだい"
        case .answering: return "こたえてね"
        case .showingResult: return "けっか"
        case .celebration: return "おめでとう！"
        case .sessionComplete: return "おわり"
        }
    }

    /// ユーザー操作を受け付けるか
    public var isInteractive: Bool {
        switch self {
        case .playing, .answering:
            return true
        case .idle, .showingResult, .celebration, .sessionComplete:
            return false
        }
    }
}
