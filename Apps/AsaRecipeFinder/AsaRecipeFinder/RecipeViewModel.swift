//
//  RecipeViewModel.swift
//  AsaRecipeFinder
//  
//  Created on 2025/07/22
//

import Foundation
import SwiftData

// MARK: - Search Type Enum

enum SearchType {
    case ingredient
    case name
    case category
}

// MARK: - Recipe View Model

@Observable
@MainActor
class RecipeViewModel {
    
    // MARK: - Properties
    
    private let recipeService: RecipeServiceProtocol
    private var modelContext: ModelContext?
    
    // Search properties
    var searchText = ""
    var searchType: SearchType = .ingredient
    var selectedCategory = ""
    var categories: [String] = []
    
    // Recipe data
    var searchResults: [Recipe] = []
    var randomRecipes: [Recipe] = []
    var favoriteRecipes: [Recipe] = []
    var selectedRecipe: Recipe?
    
    // UI state
    var isLoading = false
    var errorMessage: String?
    var showingError = false
    
    // MARK: - Initialization
    
    init(recipeService: RecipeServiceProtocol = RecipeService.shared) {
        self.recipeService = recipeService
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadFavoriteRecipes()
    }
    
    // MARK: - Search Methods
    
    func searchRecipes() async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            switch searchType {
            case .ingredient:
                searchResults = try await recipeService.searchRecipesByIngredient(searchText)
            case .name:
                searchResults = try await recipeService.searchRecipesByName(searchText)
            case .category:
                searchResults = try await recipeService.getRecipesByCategory(selectedCategory)
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            searchResults = []
        }
        
        isLoading = false
    }
    
    func loadRandomRecipes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            randomRecipes = try await recipeService.getRandomRecipes(count: 8)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isLoading = false
    }
    
    func loadCategories() async {
        do {
            categories = try await recipeService.getCategories()
            if !categories.isEmpty {
                selectedCategory = categories.first ?? ""
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    func getRecipeDetails(for recipe: Recipe) async {
        isLoading = true
        errorMessage = nil
        
        do {
            selectedRecipe = try await recipeService.getRecipeDetails(by: recipe.id)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Favorite Management
    
    func toggleFavorite(for recipe: Recipe) {
        guard let context = modelContext else { return }
        
        if let existingRecipe = favoriteRecipes.first(where: { $0.id == recipe.id }) {
            // お気に入りから削除
            context.delete(existingRecipe)
            favoriteRecipes.removeAll { $0.id == recipe.id }
        } else {
            // お気に入りに追加
            let favoriteRecipe = Recipe(
                id: recipe.id,
                title: recipe.title,
                image: recipe.image,
                readyInMinutes: recipe.readyInMinutes,
                servings: recipe.servings,
                instructions: recipe.instructions,
                ingredients: recipe.ingredients,
                category: recipe.category,
                sourceURL: recipe.sourceURL
            )
            favoriteRecipe.isFavorite = true
            
            context.insert(favoriteRecipe)
            favoriteRecipes.append(favoriteRecipe)
        }
        
        do {
            try context.save()
        } catch {
            errorMessage = "お気に入りの保存に失敗しました: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    func isFavorite(_ recipe: Recipe) -> Bool {
        return favoriteRecipes.contains { $0.id == recipe.id }
    }
    
    private func loadFavoriteRecipes() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<Recipe>(
                predicate: #Predicate { $0.isFavorite },
                sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
            )
            favoriteRecipes = try context.fetch(descriptor)
        } catch {
            errorMessage = "お気に入りの読み込みに失敗しました: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    // MARK: - Utility Methods
    
    func clearSearch() {
        searchText = ""
        searchResults = []
        selectedRecipe = nil
    }
    
    func clearError() {
        errorMessage = nil
        showingError = false
    }
    
    func refreshFavorites() {
        loadFavoriteRecipes()
    }
    
    // MARK: - Computed Properties
    
    var hasSearchResults: Bool {
        !searchResults.isEmpty
    }
    
    var hasRandomRecipes: Bool {
        !randomRecipes.isEmpty
    }
    
    var hasFavorites: Bool {
        !favoriteRecipes.isEmpty
    }
    
    var canSearch: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}