//
//  TimerCategory.swift
//  AsaTimerPro
//
//  Created on 2025/09/05
//

import Foundation
import SwiftUI

// タイマーカテゴリの列挙型
enum TimerCategory: String, CaseIterable, Codable, Identifiable {
    case work = "work"
    case study = "study"
    case exercise = "exercise"
    case rest = "rest"
    case cooking = "cooking"
    case general = "general"
    
    var id: String { self.rawValue }
    
    // カテゴリの日本語名
    var displayName: String {
        switch self {
        case .work:
            return "仕事"
        case .study:
            return "勉強"
        case .exercise:
            return "運動"
        case .rest:
            return "休憩"
        case .cooking:
            return "料理"
        case .general:
            return "一般"
        }
    }
    
    // カテゴリごとのアイコン
    var icon: String {
        switch self {
        case .work:
            return "briefcase.fill"
        case .study:
            return "book.fill"
        case .exercise:
            return "figure.run"
        case .rest:
            return "moon.fill"
        case .cooking:
            return "frying.pan.fill"
        case .general:
            return "timer"
        }
    }
    
    // カテゴリごとの色（AsaColorsに基づく）
    var color: Color {
        switch self {
        case .work:
            return Color("AsaCoffeeBrown")
        case .study:
            return Color("AsaMocha")
        case .exercise:
            return Color("AsaMutedSage")
        case .rest:
            return Color("AsaSoftCream")
        case .cooking:
            return Color("AsaDarkSlate")
        case .general:
            return Color("AsaCoffeeBrown")
        }
    }
}