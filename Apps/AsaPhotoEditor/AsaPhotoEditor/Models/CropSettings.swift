import Foundation
import CoreGraphics

// MARK: - CropSettings
/// クロップ設定を管理する構造体
struct CropSettings: Codable, Equatable {
    // MARK: - Properties

    /// クロップ領域（正規化された座標 0.0〜1.0）
    var cropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)

    /// 回転角度（度数法、90度単位）
    var rotationAngle: Double = 0

    /// 水平反転
    var isFlippedHorizontally: Bool = false

    /// 垂直反転
    var isFlippedVertically: Bool = false

    /// アスペクト比（nil = 自由）
    var aspectRatio: AspectRatio? = nil

    // MARK: - Computed Properties

    /// デフォルト値かどうか
    var isDefault: Bool {
        cropRect == CGRect(x: 0, y: 0, width: 1, height: 1) &&
        rotationAngle == 0 &&
        !isFlippedHorizontally &&
        !isFlippedVertically
    }

    /// 回転回数（90度単位）
    var rotationCount: Int {
        Int(rotationAngle / 90) % 4
    }

    // MARK: - Static Properties

    static let `default` = CropSettings()

    // MARK: - Methods

    /// 90度時計回りに回転
    mutating func rotateClockwise() {
        rotationAngle = (rotationAngle + 90).truncatingRemainder(dividingBy: 360)
    }

    /// 90度反時計回りに回転
    mutating func rotateCounterClockwise() {
        rotationAngle = (rotationAngle - 90 + 360).truncatingRemainder(dividingBy: 360)
    }

    /// 水平反転をトグル
    mutating func toggleHorizontalFlip() {
        isFlippedHorizontally.toggle()
    }

    /// 垂直反転をトグル
    mutating func toggleVerticalFlip() {
        isFlippedVertically.toggle()
    }

    /// リセット
    mutating func reset() {
        self = CropSettings.default
    }
}

// MARK: - AspectRatio
/// アスペクト比の列挙型
enum AspectRatio: String, CaseIterable, Identifiable, Codable {
    case free = "自由"
    case square = "1:1"
    case ratio4x3 = "4:3"
    case ratio3x4 = "3:4"
    case ratio16x9 = "16:9"
    case ratio9x16 = "9:16"
    case ratio3x2 = "3:2"
    case ratio2x3 = "2:3"

    var id: String { rawValue }

    /// 実際の比率（幅/高さ）
    var ratio: CGFloat? {
        switch self {
        case .free: return nil
        case .square: return 1.0
        case .ratio4x3: return 4.0 / 3.0
        case .ratio3x4: return 3.0 / 4.0
        case .ratio16x9: return 16.0 / 9.0
        case .ratio9x16: return 9.0 / 16.0
        case .ratio3x2: return 3.0 / 2.0
        case .ratio2x3: return 2.0 / 3.0
        }
    }

    /// アイコン名
    var iconName: String {
        switch self {
        case .free: return "rectangle.dashed"
        case .square: return "square"
        case .ratio4x3, .ratio3x2: return "rectangle"
        case .ratio3x4, .ratio2x3: return "rectangle.portrait"
        case .ratio16x9: return "rectangle.fill"
        case .ratio9x16: return "rectangle.portrait.fill"
        }
    }

    /// 説明
    var description: String {
        switch self {
        case .free: return "自由にクロップ"
        case .square: return "正方形（SNSアイコン向け）"
        case .ratio4x3: return "横写真（標準）"
        case .ratio3x4: return "縦写真（標準）"
        case .ratio16x9: return "ワイド（動画向け）"
        case .ratio9x16: return "縦長（ストーリー向け）"
        case .ratio3x2: return "横写真（一眼）"
        case .ratio2x3: return "縦写真（一眼）"
        }
    }
}
