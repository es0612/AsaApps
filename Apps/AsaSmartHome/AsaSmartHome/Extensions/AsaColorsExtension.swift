import SwiftUI

// MARK: - AsaColors Extension

/// ブランドカラーの拡張
extension Color {
    // MARK: - Brand Colors

    /// プライマリカラー - AsaCoffeeBrown
    static let asaCoffeeBrown = Color(hex: "C68C53")

    /// セカンダリカラー - AsaMocha
    static let asaMocha = Color(hex: "8B5A2B")

    /// ハイライトカラー - AsaSoftCream
    static let asaSoftCream = Color(hex: "E8D5B9")

    /// ニュートラルカラー - AsaDarkSlate
    static let asaDarkSlate = Color(hex: "2F3E46")

    /// アクセントカラー - AsaMutedSage
    static let asaMutedSage = Color(hex: "7A918D")

    // MARK: - Smart Home Theme Colors

    /// デバイスオンライン状態
    static let deviceOnline = Color(hex: "30D158")

    /// デバイスオフライン状態
    static let deviceOffline = Color(hex: "FF3B30")

    /// デバイス接続中
    static let deviceConnecting = Color(hex: "FF9F0A")

    /// アクティブデバイス
    static let deviceActive = Color(hex: "64D2FF")

    // MARK: - Hex Initializer

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradient Extensions

extension LinearGradient {
    /// スマートホームアプリ用グラデーション
    static let smartHomeBackground = LinearGradient(
        colors: [
            Color.asaDarkSlate,
            Color.asaDarkSlate.opacity(0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// カード用グラデーション
    static let cardBackground = LinearGradient(
        colors: [
            Color.white.opacity(0.1),
            Color.white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// アクティブデバイス用グラデーション
    static let activeDeviceGradient = LinearGradient(
        colors: [
            Color.asaCoffeeBrown.opacity(0.8),
            Color.asaCoffeeBrown.opacity(0.6)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
