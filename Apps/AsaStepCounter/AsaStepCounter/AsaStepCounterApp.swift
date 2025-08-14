//
//  AsaStepCounterApp.swift
//  AsaStepCounter
//  
//  Created on 2025/08/15
//

import SwiftUI
import SwiftData
import HealthKit

@main
struct AsaStepCounterApp: App {
    // StepCountServiceのインスタンス
    @State private var stepCountService = StepCountService()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StepRecord.self,
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
                .environment(stepCountService)
        }
        .modelContainer(sharedModelContainer)
    }
}
