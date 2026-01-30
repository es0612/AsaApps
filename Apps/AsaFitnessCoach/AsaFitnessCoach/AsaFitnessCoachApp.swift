//
//  AsaFitnessCoachApp.swift
//  AsaFitnessCoach
//
//  AIで個人に最適化された運動プランを提案するフィットネスコーチアプリ
//

import SwiftUI
import SwiftData

@main
struct AsaFitnessCoachApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            UserProfile.self,
            WorkoutPlan.self,
            Exercise.self,
            WorkoutSession.self
        ])
    }
}
