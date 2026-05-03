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
            // RootViewでEnvironment(\.modelContext)を取得し、共有のLocalDataServiceを構築する
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(familyViewModel)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - RootView

/// `@Environment(\.modelContext)` から取得した単一Contextで `LocalDataService` を構築し、
/// 配下のViewへEnvironment経由で配布する中継View。
///
/// これにより、ContentView/IdeaListView 等で個別に `LocalDataService(modelContainer:)` を
/// new することによる Context Lifecycle 問題を防止する。
///
/// - Note: `LocalDataService` は `@State` で1回だけ初期化する。`body` 内で直接 `LocalDataService(...)`
///   を呼ぶと再描画ごとに新インスタンスが生成され、ViewModelに渡したインスタンスが古いものに
///   なってしまう（クラッシュには至らないがインスタンス乱立の温床）。
private struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dataService: LocalDataService?

    var body: some View {
        ContentView()
            .environment(\.localDataService, dataService)
            .task {
                if dataService == nil {
                    dataService = LocalDataService(modelContext: modelContext)
                }
            }
    }
}

// MARK: - LocalDataService Environment

/// LocalDataService 配布用のEnvironmentKey
private struct LocalDataServiceKey: EnvironmentKey {
    static let defaultValue: LocalDataService? = nil
}

extension EnvironmentValues {
    /// アプリ全体で共有される LocalDataService（@MainActor）
    var localDataService: LocalDataService? {
        get { self[LocalDataServiceKey.self] }
        set { self[LocalDataServiceKey.self] = newValue }
    }
}
