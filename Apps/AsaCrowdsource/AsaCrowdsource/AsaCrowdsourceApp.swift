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

    /// AuthViewModel の初期化前にデモユーザーを UserDefaults に書き込む
    /// クロージャー初期化を使うことで、AuthViewModel.init() より先に setupDemoUserIfNeeded() が走る
    @StateObject private var authViewModel: AuthViewModel = {
        AsaCrowdsourceApp.setupDemoUserIfNeeded()
        return AuthViewModel()
    }()

    @StateObject private var familyViewModel = FamilyGroupViewModel()

    /// 初回起動時のデモユーザー事前設定
    /// AuthViewModel.loadPersistedUser() がこのデータを読み込んで自動サインインする
    private static func setupDemoUserIfNeeded() {
        let userKey = "AsaCrowdsource.CurrentUser"
        guard UserDefaults.standard.data(forKey: userKey) == nil else { return }

        let demoUser = User(
            id: "demo_user_papa",
            email: "papa@tanaka.example",
            displayName: "パパ"
        )

        if let data = try? JSONEncoder().encode(demoUser) {
            UserDefaults.standard.set(data, forKey: userKey)
            UserDefaults.standard.set(demoUser.id, forKey: "AsaCrowdsource.CurrentUserId")
        }
    }

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
