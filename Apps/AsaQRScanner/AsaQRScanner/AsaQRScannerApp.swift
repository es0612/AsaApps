//
//  AsaQRScannerApp.swift
//  AsaQRScanner
//  
//  Created on 2025/07/15
//


import SwiftUI
import SwiftData

@main
struct AsaQRScannerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            QRScanResult.self,
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
