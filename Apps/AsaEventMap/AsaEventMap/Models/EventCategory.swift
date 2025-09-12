//
//  EventCategory.swift
//  AsaEventMap
//  
//  Created on 2025/09/12
//

import SwiftUI

enum EventCategory: String, CaseIterable, Codable {
    case meeting = "会議"
    case conference = "カンファレンス"
    case party = "パーティー"
    case sports = "スポーツ"
    case concert = "コンサート"
    case exhibition = "展示会"
    case workshop = "ワークショップ"
    case festival = "フェスティバル"
    case dining = "食事会"
    case other = "その他"
    
    var displayName: String {
        return self.rawValue
    }
    
    var iconName: String {
        switch self {
        case .meeting:
            return "person.3"
        case .conference:
            return "building.2"
        case .party:
            return "party.popper"
        case .sports:
            return "sportscourt"
        case .concert:
            return "music.note"
        case .exhibition:
            return "photo.artframe"
        case .workshop:
            return "hammer"
        case .festival:
            return "star.circle"
        case .dining:
            return "fork.knife"
        case .other:
            return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .meeting:
            return Color("AsaCoffeeBrown")
        case .conference:
            return Color("AsaMocha")
        case .party:
            return Color("AsaSoftCream")
        case .sports:
            return .green
        case .concert:
            return .purple
        case .exhibition:
            return Color("AsaMutedSage")
        case .workshop:
            return .orange
        case .festival:
            return .red
        case .dining:
            return Color("AsaDarkSlate")
        case .other:
            return .gray
        }
    }
}