//
//  AsaCurrencyConverterApp.swift
//  AsaCurrencyConverter
//  
//  Created on 2025/07/15
//


import SwiftUI
import SwiftData

@main
struct AsaCurrencyConverterApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ConversionHistory.self,
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
