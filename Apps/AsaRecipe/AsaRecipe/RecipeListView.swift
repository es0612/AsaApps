//
//  RecipeListView.swift
//  AsaRecipe
//  
//  Created on 2025/06/30
//

import SwiftUI

struct RecipeListView: View {
    @Bindable var recipeStore: RecipeStore
    @State private var showingAddRecipe = false
    @State private var selectedCategory: RecipeCategory? = nil
    @State private var showingFavoritesOnly = false
    
    var filteredRecipes: [Recipe] {
        var recipes = recipeStore.recipes
        
        if showingFavoritesOnly {
            recipes = recipes.filter { $0.isFavorite }
        }
        
        if let category = selectedCategory {
            recipes = recipes.filter { $0.category == category }
        }
        
        return recipes.sorted { $0.dateCreated > $1.dateCreated }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                filterSection
                
                if filteredRecipes.isEmpty {
                    emptyStateView
                } else {
                    recipeList
                }
            }
            .navigationTitle("レシピ集")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddRecipe = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.asaCoffeeBrown)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddRecipe) {
                AddRecipeView(recipeStore: recipeStore)
            }
        }
    }
    
    private var filterSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { showingFavoritesOnly.toggle() }) {
                    HStack {
                        Image(systemName: showingFavoritesOnly ? "heart.fill" : "heart")
                        Text("お気に入り")
                    }
                    .font(.caption)
                    .foregroundColor(showingFavoritesOnly ? .white : .asaCoffeeBrown)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(showingFavoritesOnly ? Color.asaCoffeeBrown : Color.asaSoftCream)
                    .cornerRadius(15)
                }
                
                Spacer()
                
                Button(action: { selectedCategory = nil }) {
                    Text("すべて")
                        .font(.caption)
                        .foregroundColor(selectedCategory == nil ? .white : .asaCoffeeBrown)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategory == nil ? Color.asaCoffeeBrown : Color.asaSoftCream)
                        .cornerRadius(15)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RecipeCategory.allCases, id: \.self) { category in
                        CategoryFilterButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            action: {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color.asaSoftCream.opacity(0.5))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.asaMutedSage)
            
            Text(showingFavoritesOnly ? "お気に入りのレシピがありません" : "レシピがまだありません")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.asaDarkSlate)
            
            Text(showingFavoritesOnly ? "ハートマークでお気に入りに追加しましょう" : "新しいレシピを追加して始めましょう！")
                .font(.body)
                .foregroundColor(.asaMutedSage)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.asaSoftCream.opacity(0.3))
    }
    
    private var recipeList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredRecipes) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe, recipeStore: recipeStore)) {
                        RecipeRowView(recipe: recipe, recipeStore: recipeStore)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
        .background(Color.asaSoftCream.opacity(0.3))
    }
}

struct CategoryFilterButton: View {
    let category: RecipeCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(category.icon)
                Text(category.rawValue)
            }
            .font(.caption)
            .foregroundColor(isSelected ? .white : .asaCoffeeBrown)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.asaCoffeeBrown : Color.asaSoftCream)
            .cornerRadius(15)
        }
    }
}

struct RecipeRowView: View {
    let recipe: Recipe
    @Bindable var recipeStore: RecipeStore
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(recipe.category.icon)
                        .font(.title2)
                    
                    Text(recipe.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.asaDarkSlate)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: { recipeStore.toggleFavorite(recipe) }) {
                        Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(recipe.isFavorite ? .red : .asaMutedSage)
                            .font(.title3)
                    }
                }
                
                HStack {
                    Label("\(recipe.cookingTime)分", systemImage: "clock")
                    Label("\(recipe.servings)人分", systemImage: "person.2")
                    Spacer()
                }
                .font(.caption)
                .foregroundColor(.asaMutedSage)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    RecipeListView(recipeStore: RecipeStore())
}