//
//  ContentView.swift
//  AsaRecipeFinder
//  
//  Created on 2025/07/22
//


import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = RecipeViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 検索タブ
            RecipeSearchView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("検索")
                }
                .tag(0)
            
            // お気に入りタブ
            FavoriteRecipesView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("お気に入り")
                }
                .tag(1)
        }
        .tint(Color("AsaCoffeeBrown"))
        .onAppear {
            viewModel.setModelContext(modelContext)
            Task {
                await viewModel.loadCategories()
                await viewModel.loadRandomRecipes()
            }
        }
        .alert("エラー", isPresented: $viewModel.showingError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "不明なエラーが発生しました")
        }
    }
}

// MARK: - Recipe Search View

struct RecipeSearchView: View {
    @Bindable var viewModel: RecipeViewModel
    @State private var showingRecipeDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 検索セクション
                    searchSection
                    
                    // 検索結果または推奨レシピ
                    if viewModel.hasSearchResults {
                        searchResultsSection
                    } else if viewModel.hasRandomRecipes {
                        recommendedRecipesSection
                    }
                }
                .padding()
            }
            .navigationTitle("レシピ検索")
            .refreshable {
                Task {
                    await viewModel.loadRandomRecipes()
                }
            }
        }
        .sheet(isPresented: $showingRecipeDetail) {
            if let recipe = viewModel.selectedRecipe {
                RecipeDetailView(recipe: recipe, viewModel: viewModel)
            }
        }
    }
    
    private var searchSection: some View {
        AsaCard {
            VStack(spacing: 16) {
                // 検索タイプ選択
                Picker("検索方法", selection: $viewModel.searchType) {
                    Text("食材から検索").tag(SearchType.ingredient)
                    Text("料理名で検索").tag(SearchType.name)
                    Text("カテゴリーから検索").tag(SearchType.category)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // 検索入力
                if viewModel.searchType == .category {
                    Picker("カテゴリー", selection: $viewModel.selectedCategory) {
                        ForEach(viewModel.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                } else {
                    HStack {
                        TextField(
                            viewModel.searchType == .ingredient ? "食材を入力（例：chicken）" : "料理名を入力",
                            text: $viewModel.searchText
                        )
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            Task {
                                await viewModel.searchRecipes()
                            }
                        }
                        
                        if !viewModel.searchText.isEmpty {
                            Button("クリア") {
                                viewModel.clearSearch()
                            }
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                    }
                }
                
                // 検索ボタン
                AsaButton(
                    title: viewModel.isLoading ? "検索中..." : "検索",
                    action: {
                        Task {
                            await viewModel.searchRecipes()
                        }
                    },
                    isEnabled: viewModel.canSearch && !viewModel.isLoading
                )
            }
        }
    }
    
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("検索結果")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.searchResults, id: \.id) { recipe in
                    RecipeCardView(recipe: recipe, viewModel: viewModel) {
                        viewModel.selectedRecipe = recipe
                        showingRecipeDetail = true
                    }
                }
            }
        }
    }
    
    private var recommendedRecipesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("おすすめレシピ")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.randomRecipes, id: \.id) { recipe in
                    RecipeCardView(recipe: recipe, viewModel: viewModel) {
                        Task {
                            await viewModel.getRecipeDetails(for: recipe)
                            showingRecipeDetail = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Recipe Card View

struct RecipeCardView: View {
    let recipe: Recipe
    let viewModel: RecipeViewModel
    let onTap: () -> Void
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 8) {
                // レシピ画像
                AsyncImage(url: URL(string: recipe.image ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color("AsaSoftCream"))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // レシピ情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .lineLimit(2)
                    
                    if let category = recipe.category {
                        Text(category)
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.toggleFavorite(for: recipe)
                        }) {
                            Image(systemName: viewModel.isFavorite(recipe) ? "heart.fill" : "heart")
                                .foregroundColor(viewModel.isFavorite(recipe) ? .red : Color("AsaMutedSage"))
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Favorite Recipes View

struct FavoriteRecipesView: View {
    @Bindable var viewModel: RecipeViewModel
    @State private var showingRecipeDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.hasFavorites {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(viewModel.favoriteRecipes, id: \.id) { recipe in
                            RecipeCardView(recipe: recipe, viewModel: viewModel) {
                                viewModel.selectedRecipe = recipe
                                showingRecipeDetail = true
                            }
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "heart")
                            .font(.system(size: 60))
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Text("お気に入りレシピがありません")
                            .font(.title2)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        
                        Text("レシピを検索してお気に入りに追加しましょう")
                            .font(.body)
                            .foregroundColor(Color("AsaMutedSage"))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .navigationTitle("お気に入り")
            .refreshable {
                viewModel.refreshFavorites()
            }
        }
        .sheet(isPresented: $showingRecipeDetail) {
            if let recipe = viewModel.selectedRecipe {
                RecipeDetailView(recipe: recipe, viewModel: viewModel)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
