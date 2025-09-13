//
//  AsaWorkoutPlannerApp.swift
//  AsaWorkoutPlanner
//
//  ワークアウトプランをカスタマイズできるフィットネス管理アプリ
//

import SwiftUI
import SwiftData

@main
struct AsaWorkoutPlannerApp: App {
    // MARK: - Properties
    
    let modelContainer: ModelContainer
    
    // MARK: - Initialization
    
    init() {
        do {
            let schema = Schema([
                WorkoutPlan.self,
                Exercise.self,
                WorkoutSession.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("ModelContainerの作成に失敗しました: \(error)")
        }
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}