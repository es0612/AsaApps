//
//  AsaLocationTrackerApp.swift
//  AsaLocationTracker
//  
//  Created on 2025/07/12
//


import SwiftUI
import SwiftData

@main
struct AsaLocationTrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LocationData.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
