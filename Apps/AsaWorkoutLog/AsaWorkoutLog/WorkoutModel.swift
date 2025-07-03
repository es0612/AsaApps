//
//  WorkoutModel.swift
//  AsaWorkoutLog
//
//  Created on 2025/07/03
//

import Foundation
import SwiftUI

struct Workout: Identifiable, Codable {
    let id = UUID()
    var name: String
    var duration: TimeInterval
    var date: Date
    var category: WorkoutCategory
    var notes: String
    
    init(name: String, duration: TimeInterval, date: Date = Date(), category: WorkoutCategory = .other, notes: String = "") {
        self.name = name
        self.duration = duration
        self.date = date
        self.category = category
        self.notes = notes
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

enum WorkoutCategory: String, CaseIterable, Codable {
    case cardio = "有酸素運動"
    case strength = "筋力トレーニング"
    case flexibility = "柔軟性"
    case balance = "バランス"
    case other = "その他"
    
    var icon: String {
        switch self {
        case .cardio:
            return "heart.fill"
        case .strength:
            return "dumbbell.fill"
        case .flexibility:
            return "figure.stretching"
        case .balance:
            return "figure.yoga"
        case .other:
            return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .cardio:
            return .red
        case .strength:
            return .orange
        case .flexibility:
            return .green
        case .balance:
            return .blue
        case .other:
            return Color("AsaCoffeeBrown")
        }
    }
}