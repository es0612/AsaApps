import Foundation

// MARK: - 場所カテゴリ

/// リマインダーの場所に割り当てるカテゴリ
/// 家族の日常生活に関連するプリセットカテゴリを提供
public enum LocationCategory: String, Codable, CaseIterable, Sendable {
    case home
    case work
    case school
    case supermarket
    case station
    case hospital
    case park
    case gym
    case custom

    // MARK: - 表示名

    public var displayName: String {
        switch self {
        case .home: "自宅"
        case .work: "職場"
        case .school: "学校"
        case .supermarket: "スーパー"
        case .station: "駅"
        case .hospital: "病院"
        case .park: "公園"
        case .gym: "ジム"
        case .custom: "カスタム"
        }
    }

    // MARK: - SFSymbol名

    public var systemImageName: String {
        switch self {
        case .home: "house.fill"
        case .work: "building.2.fill"
        case .school: "graduationcap.fill"
        case .supermarket: "cart.fill"
        case .station: "tram.fill"
        case .hospital: "cross.case.fill"
        case .park: "leaf.fill"
        case .gym: "dumbbell.fill"
        case .custom: "mappin.circle.fill"
        }
    }

    // MARK: - デフォルト半径（メートル）

    public var defaultRadius: Double {
        switch self {
        case .home: 50
        case .work: 100
        case .school: 100
        case .supermarket: 80
        case .station: 60
        case .hospital: 100
        case .park: 120
        case .gym: 60
        case .custom: 100
        }
    }
}
