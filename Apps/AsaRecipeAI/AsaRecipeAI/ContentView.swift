//
//  ContentView.swift
//  AsaRecipeAI
//
//  メインコンテンツビュー
//  タブナビゲーションで各機能にアクセス
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .home
    @State private var viewModel: RecipeAIViewModel?

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel {
                TabView(selection: $selectedTab) {
                    HomeView(viewModel: viewModel)
                        .tabItem {
                            Label("ホーム", systemImage: "house.fill")
                        }
                        .tag(Tab.home)

                    FavoritesView(viewModel: viewModel)
                        .tabItem {
                            Label("お気に入り", systemImage: "heart.fill")
                        }
                        .tag(Tab.favorites)

                    HistoryView(viewModel: viewModel)
                        .tabItem {
                            Label("履歴", systemImage: "clock.fill")
                        }
                        .tag(Tab.history)

                    SettingsView(viewModel: viewModel)
                        .tabItem {
                            Label("設定", systemImage: "gearshape.fill")
                        }
                        .tag(Tab.settings)
                }
                .tint(Color("AsaCoffeeBrown"))
            } else {
                ProgressView("初期化中...")
                    .task {
                        await initializeViewModel()
                    }
            }
        }
    }

    // MARK: - Private Methods

    private func initializeViewModel() async {
        let dataService = DataService(modelContext: modelContext)
        let recipeAIService = RecipeAIService()
        let visionService = VisionService()

        viewModel = RecipeAIViewModel(
            recipeAIService: recipeAIService,
            visionService: visionService,
            dataService: dataService
        )
    }
}

// MARK: - Tab

extension ContentView {
    /// タブの種類
    enum Tab: String, CaseIterable {
        case home
        case favorites
        case history
        case settings
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [
            Ingredient.self,
            Recipe.self,
            RecognitionHistory.self,
            UserPreferences.self,
        ], inMemory: true)
}
