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
        let dataService = LocalDataService(modelContainer: modelContext.container)
        familyViewModel.setDataService(dataService)

        if let user = authViewModel.currentUser {
            familyViewModel.setCurrentUserId(user.id)
        }
    }

    private func loadInitialData() async {
        await familyViewModel.loadInitialData()
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(FamilyGroupViewModel())
}
