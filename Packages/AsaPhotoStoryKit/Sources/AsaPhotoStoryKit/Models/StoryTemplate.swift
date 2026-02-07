import Foundation

// MARK: - StoryTemplate

/// ストーリーのテンプレート種類
public enum StoryTemplate: String, CaseIterable, Codable, Sendable {
    case blank
    case travel
    case familyEvent
    case dailyLife
    case birthday
    case season
    case milestone

    // MARK: - Properties

    public var displayName: String {
        switch self {
        case .blank: "白紙"
        case .travel: "旅行"
        case .familyEvent: "家族イベント"
        case .dailyLife: "日常"
        case .birthday: "誕生日"
        case .season: "季節"
        case .milestone: "記念日"
        }
    }

    public var iconName: String {
        switch self {
        case .blank: "doc"
        case .travel: "airplane"
        case .familyEvent: "figure.2.and.child.holdinghands"
        case .dailyLife: "sun.max"
        case .birthday: "birthday.cake"
        case .season: "leaf"
        case .milestone: "star"
        }
    }

    public var defaultPageCount: Int {
        switch self {
        case .blank: 1
        case .travel: 5
        case .familyEvent: 4
        case .dailyLife: 3
        case .birthday: 4
        case .season: 4
        case .milestone: 3
        }
    }
}
