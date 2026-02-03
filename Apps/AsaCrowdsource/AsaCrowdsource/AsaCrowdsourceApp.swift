//
//  AsaCrowdsourceApp.swift
//  AsaCrowdsource
//
//  家族でアイデアを共有するクラウドソーシングアプリ
//

import SwiftUI
import SwiftData

@main
struct AsaCrowdsourceApp: App {
    // MARK: - Properties

    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var familyViewModel = FamilyGroupViewModel()

    // MARK: - SwiftData Model Container

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Idea.self,
            Comment.self,
            Vote.self,
            LocalFamilyGroup.self,
            LocalMember.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("ModelContainerの作成に失敗しました: \(error)")
        }
    }()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(familyViewModel)
        }
        .modelContainer(sharedModelContainer)
    }
}
