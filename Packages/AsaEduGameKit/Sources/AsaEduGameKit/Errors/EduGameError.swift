import Foundation

// MARK: - エラー定義

/// AsaEduGame共通エラー
public enum EduGameError: Error, LocalizedError, Sendable {
    /// データの保存に失敗
    case saveFailed(String)
    /// データの読み込みに失敗
    case fetchFailed(String)
    /// データの削除に失敗
    case deleteFailed(String)
    /// プロフィールが見つからない
    case profileNotFound
    /// 問題生成に失敗
    case questionGenerationFailed(String)
    /// 不正なゲームモード
    case invalidGameMode
    /// 不正な難易度
    case invalidDifficulty
    /// セッションが見つからない
    case sessionNotFound
    /// 手書き認識に失敗
    case handwritingRecognitionFailed(String)
    /// ML モデルの読み込みに失敗
    case mlModelLoadFailed(String)

    public var errorDescription: String? {
        switch self {
        case .saveFailed(let detail):
            return "データの保存に失敗しました: \(detail)"
        case .fetchFailed(let detail):
            return "データの読み込みに失敗しました: \(detail)"
        case .deleteFailed(let detail):
            return "データの削除に失敗しました: \(detail)"
        case .profileNotFound:
            return "プロフィールが見つかりません"
        case .questionGenerationFailed(let detail):
            return "問題の生成に失敗しました: \(detail)"
        case .invalidGameMode:
            return "無効なゲームモードです"
        case .invalidDifficulty:
            return "無効な難易度です"
        case .sessionNotFound:
            return "ゲームセッションが見つかりません"
        case .handwritingRecognitionFailed(let detail):
            return "手書き認識に失敗しました: \(detail)"
        case .mlModelLoadFailed(let detail):
            return "MLモデルの読み込みに失敗しました: \(detail)"
        }
    }
}
