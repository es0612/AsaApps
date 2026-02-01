import Foundation

/// 家系図アプリのエラー定義
public enum FamilyTreeError: Error, LocalizedError, Sendable {
    case memberNotFound
    case treeNotFound
    case marriageNotFound
    case invalidRelationship
    case duplicateMember
    case circularRelationship
    case dataCorruption
    case exportFailed(String)
    case importFailed(String)
    case validationError(String)
    case storageError(String)

    public var errorDescription: String? {
        switch self {
        case .memberNotFound:
            return "メンバーが見つかりません"
        case .treeNotFound:
            return "家系図が見つかりません"
        case .marriageNotFound:
            return "婚姻関係が見つかりません"
        case .invalidRelationship:
            return "無効な関係です"
        case .duplicateMember:
            return "メンバーが重複しています"
        case .circularRelationship:
            return "循環する関係は作成できません（例：自分自身の親になる）"
        case .dataCorruption:
            return "データが破損しています"
        case .exportFailed(let message):
            return "エクスポートに失敗しました: \(message)"
        case .importFailed(let message):
            return "インポートに失敗しました: \(message)"
        case .validationError(let message):
            return "入力エラー: \(message)"
        case .storageError(let message):
            return "保存エラー: \(message)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .memberNotFound, .treeNotFound, .marriageNotFound:
            return "データを再読み込みしてください"
        case .invalidRelationship, .circularRelationship:
            return "関係を見直して、正しい親子関係を設定してください"
        case .duplicateMember:
            return "同じメンバーを追加しないでください"
        case .dataCorruption:
            return "アプリを再起動してください。問題が続く場合はデータをリセットしてください"
        case .exportFailed, .importFailed:
            return "再度お試しください"
        case .validationError:
            return "入力内容を確認してください"
        case .storageError:
            return "ストレージの空き容量を確認してください"
        }
    }
}
