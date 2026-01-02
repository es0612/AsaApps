//
//  CustomCategory.swift
//  AsaSmartTodo
//
//  ユーザー定義カテゴリモデル
//  システムカテゴリ以外の独自カテゴリを管理
//

import Foundation
import SwiftUI
import SwiftData

@Model
final class CustomCategory {
    var id: UUID
    var name: String                    // カテゴリ名
    var icon: String                    // emoji
    var importanceWeight: Double        // 0.0-1.0
    var colorHex: String                // #RRGGBB
    var isSystem: Bool                  // システムカテゴリか
    var createdAt: Date
    var updatedAt: Date

    init(
        name: String,
        icon: String,
        importanceWeight: Double,
        colorHex: String,
        isSystem: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.importanceWeight = min(max(importanceWeight, 0.0), 1.0)
        self.colorHex = colorHex
        self.isSystem = isSystem
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// 色をSwiftUI Colorに変換
    var color: Color {
        Color(hex: colorHex) ?? Color.gray
    }
}

// MARK: - Color Extension (HEX対応)

extension Color {
    /// HEX文字列からColorを初期化
    /// - Parameter hex: "#RRGGBB" 形式の文字列
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

    /// ColorをHEX文字列に変換
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components,
              components.count >= 3 else {
            return nil
        }

        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
