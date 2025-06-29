//
//  RecipeDetailView.swift
//  AsaRecipe
//  
//  Created on 2025/06/30
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @Bindable var recipeStore: RecipeStore
    @State private var showingEditView = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                quickInfoSection
                ingredientsSection
                instructionsSection
            }
            .padding()
        }
        .background(Color.asaSoftCream.opacity(0.3))
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { recipeStore.toggleFavorite(recipe) }) {
                        Label(
                            recipe.isFavorite ? "お気に入りから削除" : "お気に入りに追加",
                            systemImage: recipe.isFavorite ? "heart.fill" : "heart"
                        )
                    }
                    
                    Button(action: { showingEditView = true }) {
                        Label("編集", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { recipeStore.deleteRecipe(recipe) }) {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.asaCoffeeBrown)
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditRecipeView(recipe: recipe, recipeStore: recipeStore)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(recipe.category.icon)
                    .font(.largeTitle)
                
                VStack(alignment: .leading) {
                    Text(recipe.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.asaDarkSlate)
                    
                    Text(recipe.category.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.asaMutedSage)
                }
                
                Spacer()
                
                Button(action: { recipeStore.toggleFavorite(recipe) }) {
                    Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(recipe.isFavorite ? .red : .asaMutedSage)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
    
    private var quickInfoSection: some View {
        HStack(spacing: 20) {
            InfoCard(
                icon: "clock",
                title: "調理時間",
                value: "\(recipe.cookingTime)分"
            )
            
            InfoCard(
                icon: "person.2",
                title: "人数",
                value: "\(recipe.servings)人分"
            )
            
            Spacer()
        }
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "材料", icon: "list.bullet")
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                    HStack {
                        Circle()
                            .fill(Color.asaCoffeeBrown)
                            .frame(width: 6, height: 6)
                        
                        Text(ingredient)
                            .foregroundColor(.asaDarkSlate)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(12)
            .shadow(radius: 1)
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "作り方", icon: "list.number")
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.asaCoffeeBrown)
                            .clipShape(Circle())
                        
                        Text(instruction)
                            .foregroundColor(.asaDarkSlate)
                            .lineLimit(nil)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(12)
            .shadow(radius: 1)
        }
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.asaCoffeeBrown)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.asaMutedSage)
            
            Text(value)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.asaDarkSlate)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.asaCoffeeBrown)
            
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.asaDarkSlate)
            
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        RecipeDetailView(
            recipe: Recipe(
                name: "カレーライス",
                ingredients: ["玉ねぎ 1個", "にんじん 1本"],
                instructions: ["野菜を切る", "炒める"],
                cookingTime: 30,
                servings: 4,
                category: .main
            ),
            recipeStore: RecipeStore()
        )
    }
}