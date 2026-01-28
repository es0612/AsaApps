import Foundation
import SwiftUI

// MARK: - TextLayer
/// テキストレイヤーを管理する構造体
struct TextLayer: Identifiable, Codable, Equatable {
    // MARK: - Properties

    let id: UUID
    var text: String
    var fontName: String
    var fontSize: CGFloat
    var colorHex: String
    var position: CGPoint // 正規化された座標 (0.0〜1.0)
    var rotation: Double // ラジアン
    var opacity: Double
    var isSelected: Bool

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        text: String = "テキスト",
        fontName: String = "HiraginoSans-W6",
        fontSize: CGFloat = 32,
        colorHex: String = "#FFFFFF",
        position: CGPoint = CGPoint(x: 0.5, y: 0.5),
        rotation: Double = 0,
        opacity: Double = 1.0,
        isSelected: Bool = false
    ) {
        self.id = id
        self.text = text
        self.fontName = fontName
        self.fontSize = fontSize
        self.colorHex = colorHex
        self.position = position
        self.rotation = rotation
        self.opacity = opacity
        self.isSelected = isSelected
    }

    // MARK: - Computed Properties

    var color: Color {
        Color(hex: colorHex) ?? .white
    }

    var font: Font {
        .custom(fontName, size: fontSize)
    }

    var uiFont: UIFont {
        UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .semibold)
    }

    // MARK: - Methods

    mutating func updateColor(_ newColor: Color) {
        colorHex = newColor.toHex() ?? "#FFFFFF"
    }
}

// MARK: - FontOption
/// 使用可能なフォントの列挙型
enum FontOption: String, CaseIterable, Identifiable {
    case hiraginoSansW3 = "HiraginoSans-W3"
    case hiraginoSansW6 = "HiraginoSans-W6"
    case hiraginoSansW7 = "HiraginoSans-W7"
    case hiraginoMinchoW3 = "HiraMinProN-W3"
    case hiraginoMinchoW6 = "HiraMinProN-W6"
    case avenir = "Avenir-Medium"
    case avenirHeavy = "Avenir-Heavy"
    case georgia = "Georgia"
    case palatino = "Palatino-Roman"
    case courier = "Courier"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hiraginoSansW3: return "ヒラギノ角ゴ W3"
        case .hiraginoSansW6: return "ヒラギノ角ゴ W6"
        case .hiraginoSansW7: return "ヒラギノ角ゴ W7"
        case .hiraginoMinchoW3: return "ヒラギノ明朝 W3"
        case .hiraginoMinchoW6: return "ヒラギノ明朝 W6"
        case .avenir: return "Avenir Medium"
        case .avenirHeavy: return "Avenir Heavy"
        case .georgia: return "Georgia"
        case .palatino: return "Palatino"
        case .courier: return "Courier"
        }
    }

    var font: Font {
        .custom(rawValue, size: 16)
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }

        let r: CGFloat = components.count > 0 ? components[0] : 0
        let g: CGFloat = components.count > 1 ? components[1] : 0
        let b: CGFloat = components.count > 2 ? components[2] : 0

        return String(format: "#%02X%02X%02X",
                      Int(r * 255),
                      Int(g * 255),
                      Int(b * 255))
    }
}
