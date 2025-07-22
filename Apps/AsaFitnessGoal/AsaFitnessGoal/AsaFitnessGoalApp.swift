//
//  AsaFitnessGoalApp.swift
//  AsaFitnessGoal
//  
//  Created on 2025/07/19
//

import SwiftUI
import SwiftData
import HealthKit

@main
struct AsaFitnessGoalApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FitnessGoal.self,
            WorkoutRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("ModelContainer作成エラー: \(error)")
            print("インメモリコンテナにフォールバックします")
            
            // フォールバック：インメモリコンテナを作成
            let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                fatalError("フォールバックModelContainerの作成にも失敗しました: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
