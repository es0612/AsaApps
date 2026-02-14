import Foundation

// MARK: - DataSource

/// データソース種別
public enum DataSource: String, CaseIterable, Codable, Sendable {
    case manual
    case healthKit
    case coreLocation
    case photoLibrary
    case coreMotion

    /// 日本語表示名
    public var displayName: String {
        switch self {
        case .manual: return "手動入力"
        case .healthKit: return "ヘルスケア"
        case .coreLocation: return "位置情報"
        case .photoLibrary: return "写真ライブラリ"
        case .coreMotion: return "モーション"
        }
    }
}
