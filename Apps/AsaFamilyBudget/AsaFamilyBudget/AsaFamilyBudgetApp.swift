//
//  AsaFamilyBudgetApp.swift
//  AsaFamilyBudget
//
//  Created by Asa Apps on 2025.
//

import SwiftUI
import SwiftData

@main
struct AsaFamilyBudgetApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                Budget.self,
                Transaction.self,
                Category.self,
                FamilyMember.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("モデルコンテナの初期化に失敗しました: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}