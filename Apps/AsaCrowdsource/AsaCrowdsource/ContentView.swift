//
//  ContentView.swift
//  AsaCrowdsource
//
//  メインコンテンツビュー
//

import SwiftUI
import SwiftData
import AsaUIKit

struct ContentView: View {
    // MARK: - Properties

    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var familyViewModel: FamilyGroupViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.localDataService) private var localDataService

    @State private var selectedTab = 0

    // MARK: - Body

    var body: some View {
        Group {
            switch authViewModel.authState {
            case .unknown:
                loadingView

            case .signedOut:
                LoginView()

            case .signedIn:
                mainTabView
            }
        }
        .animation(.easeInOut(duration: 0.2), value: authViewModel.authState)
        // localDataService がEnvironment経由で利用可能になるまで待つため task(id:) を使用。
        // RootView の .task で dataService が非nilに切り替わるとこのタスクが再起動する。
        .task(id: localDataService != nil) {
            guard localDataService != nil else { return }
            await loadDemoSampleDataIfNeeded()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(AsaColors.coffeeBrown))

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(AsaColors.coffeeBrown)))

            Text("読み込み中...")
                .font(.subheadline)
                .foregroundColor(Color(AsaColors.mutedSage))
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            // アイデア一覧
            IdeaListView()
                .tabItem {
                    Image(systemName: "lightbulb.fill")
                    Text("アイデア")
                }
                .tag(0)

            // グループ管理
            FamilyDashboardView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("グループ")
                }
                .tag(1)

            // 設定
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("設定")
                }
                .tag(2)
        }
        .tint(Color(AsaColors.coffeeBrown))
        .onAppear {
            setupFamilyViewModel()
        }
        .task {
            await loadInitialData()
        }
    }

    // MARK: - Private Methods

    private func setupFamilyViewModel() {
        // Environment経由で配布された共有のLocalDataServiceを利用（毎回new禁止）
        guard let dataService = localDataService else { return }
        familyViewModel.setDataService(dataService)

        if let user = authViewModel.currentUser {
            familyViewModel.setCurrentUserId(user.id)
        }
    }

    private func loadInitialData() async {
        await familyViewModel.loadInitialData()
    }

    /// 初回起動時（およびデータが空のとき）にデモ用サンプルデータを自動投入
    /// - 判定基準: UserDefaults フラグではなく **実データの存在**（fetchUserGroups の結果が空かどうか）
    ///   → SwiftData ストアと UserDefaults フラグの状態がズレても自動復旧する
    /// - 副作用: ユーザーが手動で全グループを削除した場合は次回起動でサンプル復活する（デモ用途として許容）
    private func loadDemoSampleDataIfNeeded() async {
        guard let user = authViewModel.currentUser else { return }
        guard let dataService = localDataService else { return }

        // 既にグループが存在すればサンプル投入をスキップ
        do {
            let existingGroups = try await dataService.fetchUserGroups(userId: user.id)
            guard existingGroups.isEmpty else {
                familyViewModel.setDataService(dataService)
                familyViewModel.setCurrentUserId(user.id)
                await familyViewModel.loadInitialData()
                return
            }
        } catch {
            print("既存グループ取得エラー: \(error.localizedDescription)")
            return
        }

        // FamilyGroupViewModel に dataService を設定
        familyViewModel.setDataService(dataService)
        familyViewModel.setCurrentUserId(user.id)

        // サンプルデータを投入（共有のmodelContextを直接利用）
        let sampleService = SampleDataService(modelContext: modelContext)
        do {
            try sampleService.loadSampleData(ownerUserId: user.id)
            await familyViewModel.loadInitialData()
        } catch {
            print("サンプルデータ投入エラー: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(FamilyGroupViewModel())
}
