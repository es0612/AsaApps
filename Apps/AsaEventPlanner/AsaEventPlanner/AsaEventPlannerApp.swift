//
//  AsaEventPlannerApp.swift
//  AsaEventPlanner
//  
//  Created on 2025/08/03
//


import SwiftUI
import SwiftData

@main
struct AsaEventPlannerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(ModelContainer.shared)
    }
}
