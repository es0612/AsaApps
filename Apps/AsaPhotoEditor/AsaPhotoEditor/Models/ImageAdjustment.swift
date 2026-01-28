import Foundation

// MARK: - ImageAdjustment
/// 画像調整パラメータを管理する構造体
/// 非破壊編集のため、オリジナル画像に適用するパラメータのみを保持
struct ImageAdjustment: Codable, Equatable, Sendable {
    // MARK: - Properties

    /// 明るさ (-1.0 ~ 1.0)
    var brightness: Double = 0.0

    /// コントラスト (0.5 ~ 2.0)
    var contrast: Double = 1.0

    /// 彩度 (0.0 ~ 2.0)
    var saturation: Double = 1.0

    /// 露出 (-2.0 ~ 2.0)
    var exposure: Double = 0.0

    /// シャープネス (0.0 ~ 1.0)
    var sharpness: Double = 0.0

    /// ハイライト (-1.0 ~ 1.0)
    var highlights: Double = 0.0

    /// シャドウ (-1.0 ~ 1.0)
    var shadows: Double = 0.0

    // MARK: - Computed Properties

    /// デフォルト値かどうか
    var isDefault: Bool {
        self == ImageAdjustment()
    }

    // MARK: - Static Properties

    /// デフォルト値
    static let `default` = ImageAdjustment()

    // MARK: - Range Definitions

    static let brightnessRange: ClosedRange<Double> = -1.0...1.0
    static let contrastRange: ClosedRange<Double> = 0.5...2.0
    static let saturationRange: ClosedRange<Double> = 0.0...2.0
    static let exposureRange: ClosedRange<Double> = -2.0...2.0
    static let sharpnessRange: ClosedRange<Double> = 0.0...1.0
    static let highlightsRange: ClosedRange<Double> = -1.0...1.0
    static let shadowsRange: ClosedRange<Double> = -1.0...1.0
}

// MARK: - AdjustmentType
/// 調整タイプの列挙型
enum AdjustmentType: String, CaseIterable, Identifiable {
    case brightness = "明るさ"
    case contrast = "コントラスト"
    case saturation = "彩度"
    case exposure = "露出"
    case sharpness = "シャープネス"
    case highlights = "ハイライト"
    case shadows = "シャドウ"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .brightness: return "sun.max"
        case .contrast: return "circle.lefthalf.filled"
        case .saturation: return "drop.fill"
        case .exposure: return "camera.aperture"
        case .sharpness: return "triangle"
        case .highlights: return "sun.max.fill"
        case .shadows: return "moon.fill"
        }
    }

    var range: ClosedRange<Double> {
        switch self {
        case .brightness: return ImageAdjustment.brightnessRange
        case .contrast: return ImageAdjustment.contrastRange
        case .saturation: return ImageAdjustment.saturationRange
        case .exposure: return ImageAdjustment.exposureRange
        case .sharpness: return ImageAdjustment.sharpnessRange
        case .highlights: return ImageAdjustment.highlightsRange
        case .shadows: return ImageAdjustment.shadowsRange
        }
    }

    var defaultValue: Double {
        switch self {
        case .brightness: return 0.0
        case .contrast: return 1.0
        case .saturation: return 1.0
        case .exposure: return 0.0
        case .sharpness: return 0.0
        case .highlights: return 0.0
        case .shadows: return 0.0
        }
    }

    func getValue(from adjustment: ImageAdjustment) -> Double {
        switch self {
        case .brightness: return adjustment.brightness
        case .contrast: return adjustment.contrast
        case .saturation: return adjustment.saturation
        case .exposure: return adjustment.exposure
        case .sharpness: return adjustment.sharpness
        case .highlights: return adjustment.highlights
        case .shadows: return adjustment.shadows
        }
    }

    func setValue(_ value: Double, to adjustment: inout ImageAdjustment) {
        switch self {
        case .brightness: adjustment.brightness = value
        case .contrast: adjustment.contrast = value
        case .saturation: adjustment.saturation = value
        case .exposure: adjustment.exposure = value
        case .sharpness: adjustment.sharpness = value
        case .highlights: adjustment.highlights = value
        case .shadows: adjustment.shadows = value
        }
    }
}
