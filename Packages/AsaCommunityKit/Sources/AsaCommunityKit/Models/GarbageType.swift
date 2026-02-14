import Foundation

// MARK: - GarbageType

/// ゴミの種類（7種）
public enum GarbageType: String, CaseIterable, Sendable {
    case burnable = "燃えるゴミ"
    case nonBurnable = "燃えないゴミ"
    case recyclePlastic = "プラスチック"
    case recyclePaper = "古紙"
    case recycleCan = "缶"
    case recycleBottle = "ビン"
    case recyclePET = "ペットボトル"

    /// SF Symbol名
    public var iconName: String {
        switch self {
        case .burnable: return "flame"
        case .nonBurnable: return "xmark.bin"
        case .recyclePlastic: return "arrow.3.trianglepath"
        case .recyclePaper: return "newspaper"
        case .recycleCan: return "cylinder"
        case .recycleBottle: return "waterbottle"
        case .recyclePET: return "waterbottle.fill"
        }
    }

    /// カラー（hex文字列）
    public var colorHex: String {
        switch self {
        case .burnable: return "#D0021B"
        case .nonBurnable: return "#4A4A4A"
        case .recyclePlastic: return "#F5A623"
        case .recyclePaper: return "#7ED321"
        case .recycleCan: return "#4A90D9"
        case .recycleBottle: return "#50E3C2"
        case .recyclePET: return "#BD10E0"
        }
    }
}
