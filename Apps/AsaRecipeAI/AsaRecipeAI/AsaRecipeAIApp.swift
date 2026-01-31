//
//  AsaRecipeAIApp.swift
//  AsaRecipeAI
//
//  画像からレシピを提案するAIアプリ
//  Foundation Models + Vision でオンデバイスAI
//

import SwiftUI
import SwiftData

@main
struct AsaRecipeAIApp: App {
    // MARK: - Properties

    /// Swift Data のモデルコンテナ
    let modelContainer: ModelContainer

    // MARK: - Initialization

    init() {
        do {
            let schema = Schema([
                Ingredient.self,
                Recipe.self,
                RecognitionHistory.self,
                UserPreferences.self,
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
            fatalError("SwiftDataの初期化に失敗しました: \(error)")
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
