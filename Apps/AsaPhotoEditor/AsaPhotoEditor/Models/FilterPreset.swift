import Foundation
import SwiftUI

// MARK: - FilterPreset
/// フィルタープリセットの列挙型
/// Core Imageのフィルターと対応
enum FilterPreset: String, CaseIterable, Identifiable, Codable {
    case none = "オリジナル"
    case sepia = "セピア"
    case noir = "ノワール"
    case vintage = "ビンテージ"
    case vivid = "ビビッド"
    case dramatic = "ドラマチック"
    case mono = "モノクロ"
    case tonal = "トーナル"
    case fade = "フェード"
    case chrome = "クローム"
    case process = "プロセス"
    case transfer = "トランスファー"
    case blur = "ぼかし"
    case pixellate = "モザイク"

    var id: String { rawValue }

    /// Core Imageフィルター名
    var ciFilterName: String? {
        switch self {
        case .none: return nil
        case .sepia: return "CISepiaTone"
        case .noir: return "CIPhotoEffectNoir"
        case .vintage: return "CIPhotoEffectInstant"
        case .vivid: return "CIColorControls" // カスタム設定
        case .dramatic: return "CIPhotoEffectDramatic" // iOS 17未対応の場合はカスタム
        case .mono: return "CIPhotoEffectMono"
        case .tonal: return "CIPhotoEffectTonal"
        case .fade: return "CIPhotoEffectFade"
        case .chrome: return "CIPhotoEffectChrome"
        case .process: return "CIPhotoEffectProcess"
        case .transfer: return "CIPhotoEffectTransfer"
        case .blur: return "CIGaussianBlur"
        case .pixellate: return "CIPixellate"
        }
    }

    /// 強度調整が可能かどうか
    var supportsIntensity: Bool {
        switch self {
        case .sepia, .blur, .pixellate, .vivid:
            return true
        default:
            return false
        }
    }

    /// デフォルト強度
    var defaultIntensity: Double {
        switch self {
        case .sepia: return 0.8
        case .blur: return 10.0
        case .pixellate: return 10.0
        case .vivid: return 1.3
        default: return 1.0
        }
    }

    /// 強度の範囲
    var intensityRange: ClosedRange<Double> {
        switch self {
        case .sepia: return 0.0...1.0
        case .blur: return 0.0...50.0
        case .pixellate: return 1.0...50.0
        case .vivid: return 0.5...2.0
        default: return 0.0...1.0
        }
    }

    /// アイコン名
    var iconName: String {
        switch self {
        case .none: return "photo"
        case .sepia: return "paintbrush"
        case .noir: return "moon.fill"
        case .vintage: return "camera.viewfinder"
        case .vivid: return "sparkles"
        case .dramatic: return "theatermasks"
        case .mono: return "circle.lefthalf.filled"
        case .tonal: return "dial.low"
        case .fade: return "cloud"
        case .chrome: return "circle.hexagongrid"
        case .process: return "gearshape.2"
        case .transfer: return "arrow.triangle.2.circlepath"
        case .blur: return "drop.circle"
        case .pixellate: return "square.grid.3x3"
        }
    }

    /// フィルターの説明
    var description: String {
        switch self {
        case .none: return "元の画像"
        case .sepia: return "温かみのあるセピア調"
        case .noir: return "クラシックな白黒"
        case .vintage: return "レトロな色合い"
        case .vivid: return "鮮やかな色彩"
        case .dramatic: return "コントラストを強調"
        case .mono: return "シンプルなモノクロ"
        case .tonal: return "トーンを調整"
        case .fade: return "淡く柔らかい印象"
        case .chrome: return "メタリックな輝き"
        case .process: return "独特の色調"
        case .transfer: return "ノスタルジック"
        case .blur: return "ぼかし効果"
        case .pixellate: return "ピクセル化"
        }
    }
}

// MARK: - FilterSettings
/// フィルター設定を保持する構造体
struct FilterSettings: Codable, Equatable {
    var preset: FilterPreset = .none
    var intensity: Double = 1.0

    var isDefault: Bool {
        preset == .none
    }

    static let `default` = FilterSettings()
}
