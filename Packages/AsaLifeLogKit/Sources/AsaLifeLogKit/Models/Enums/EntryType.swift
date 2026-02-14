import Foundation

// MARK: - EntryType

/// ライフログエントリーの種別
public enum EntryType: String, CaseIterable, Codable, Sendable {
    case manual
    case health
    case location
    case photo
    case activity
    case mood

    /// 日本語表示名
    public var displayName: String {
        switch self {
        case .manual: return "手動記録"
        case .health: return "ヘルスケア"
        case .location: return "位置情報"
        case .photo: return "写真"
        case .activity: return "アクティビティ"
        case .mood: return "気分"
        }
    }

    /// SF Symbol名
    public var icon: String {
        switch self {
        case .manual: return "pencil.and.list.clipboard"
        case .health: return "heart.fill"
        case .location: return "location.fill"
        case .photo: return "photo.fill"
        case .activity: return "figure.walk"
        case .mood: return "face.smiling"
        }
    }
}
