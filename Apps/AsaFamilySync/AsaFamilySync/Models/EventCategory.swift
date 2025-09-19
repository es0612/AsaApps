import Foundation
import SwiftUI

enum EventCategory: String, Codable, CaseIterable {
    case work = "work"
    case school = "school"
    case household = "household"
    case leisure = "leisure"
    case health = "health"
    case shopping = "shopping"
    case meal = "meal"
    case meeting = "meeting"
    case other = "other"

    var displayName: String {
        switch self {
        case .work: return "仕事"
        case .school: return "学校"
        case .household: return "家事"
        case .leisure: return "レジャー"
        case .health: return "健康・医療"
        case .shopping: return "買い物"
        case .meal: return "食事"
        case .meeting: return "会議・面談"
        case .other: return "その他"
        }
    }

    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .school: return "graduationcap.fill"
        case .household: return "house.fill"
        case .leisure: return "gamecontroller.fill"
        case .health: return "heart.fill"
        case .shopping: return "cart.fill"
        case .meal: return "fork.knife"
        case .meeting: return "person.2.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .work: return Color(hex: "#2F3E46") // AsaDarkSlate
        case .school: return Color(hex: "#4ECDC4")
        case .household: return Color(hex: "#C68C53") // AsaCoffeeBrown
        case .leisure: return Color(hex: "#FF6B6B")
        case .health: return Color(hex: "#96CEB4")
        case .shopping: return Color(hex: "#8B5A2B") // AsaMocha
        case .meal: return Color(hex: "#FECA57")
        case .meeting: return Color(hex: "#54A0FF")
        case .other: return Color(hex: "#7A918D") // AsaMutedSage
        }
    }
}

extension Color {
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
            (a, r, g, b) = (255, 0, 0, 0)
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