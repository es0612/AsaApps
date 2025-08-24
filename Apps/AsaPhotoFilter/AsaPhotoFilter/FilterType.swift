import Foundation
import CoreImage

enum FilterType: String, CaseIterable {
    case none = "none"
    case sepia = "CISepiaTone" 
    case noir = "CIPhotoEffectNoir"
    case vintage = "CIPhotoEffectInstant"
    case vivid = "CIPhotoEffectVivid"
    case dramatic = "CIPhotoEffectDramatic"
    case mono = "CIPhotoEffectMono"
    case tonal = "CIPhotoEffectTonal"
    
    var displayName: String {
        switch self {
        case .none:
            return "フィルターなし"
        case .sepia:
            return "セピア"
        case .noir:
            return "ノワール"
        case .vintage:
            return "ビンテージ"
        case .vivid:
            return "鮮やか"
        case .dramatic:
            return "ドラマチック"
        case .mono:
            return "モノクロ"
        case .tonal:
            return "トーン調整"
        }
    }
    
    var description: String {
        switch self {
        case .none:
            return "元の画像のまま"
        case .sepia:
            return "温かみのあるセピア調"
        case .noir:
            return "クラシックな白黒"
        case .vintage:
            return "レトロなインスタント風"
        case .vivid:
            return "色鮮やかな仕上がり"
        case .dramatic:
            return "コントラストの強い印象的な仕上がり"
        case .mono:
            return "シンプルなモノクロ"
        case .tonal:
            return "色調を調整したソフトな仕上がり"
        }
    }
    
    var supportsIntensity: Bool {
        switch self {
        case .sepia:
            return true
        default:
            return false
        }
    }
}