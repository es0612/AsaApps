//
//  RecipeDetailView.swift
//  AsaRecipeFinder
//  
//  Created on 2025/07/22
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @Bindable var viewModel: RecipeViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // レシピ画像
                    recipeImageSection
                    
                    // レシピ情報
                    VStack(alignment: .leading, spacing: 16) {
                        recipeInfoSection
                        
                        // 材料セクション
                        if !recipe.ingredients.isEmpty {
                            ingredientsSection
                        }
                        
                        // 作り方セクション
                        if !recipe.instructions.isEmpty {
                            instructionsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(recipe.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    favoriteButton
                }
            }
        }
    }
    
    private var recipeImageSection: some View {
        AsyncImage(url: URL(string: recipe.image ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color("AsaSoftCream"))
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.artframe")
                            .font(.system(size: 40))
                            .foregroundColor(Color("AsaMutedSage"))
                        Text("画像なし")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                }
        }
        .frame(height: 250)
        .clipShape(Rectangle())
    }
    
    private var recipeInfoSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(recipe.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                if let category = recipe.category {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(Color("AsaMutedSage"))
                        Text(category)
                            .font(.subheadline)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        Spacer()
                    }
                }
                
                HStack {
                    if let readyInMinutes = recipe.readyInMinutes {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(Color("AsaMutedSage"))
                                Text("調理時間")
                                    .font(.caption)
                                    .foregroundColor(Color("AsaMutedSage"))
                            }
                            Text("\(readyInMinutes)分")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                    }
                    
                    Spacer()
                    
                    if let servings = recipe.servings {
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack {
                                Image(systemName: "person.2")
                                    .foregroundColor(Color("AsaMutedSage"))
                                Text("人数")
                                    .font(.caption)
                                    .foregroundColor(Color("AsaMutedSage"))
                            }
                            Text("\(servings)人分")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                    }
                }
            }
        }
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("材料")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            AsaCard {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                        HStack {
                            Circle()
                                .fill(Color("AsaCoffeeBrown"))
                                .frame(width: 6, height: 6)
                            
                            Text(ingredient.name)
                                .font(.body)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            Spacer()
                            
                            if let amount = ingredient.amount, !amount.isEmpty {
                                Text(amount)
                                    .font(.body)
                                    .foregroundColor(Color("AsaMutedSage"))
                            }
                        }
                        
                        if index < recipe.ingredients.count - 1 {
                            Divider()
                                .background(Color("AsaSoftCream"))
                        }
                    }
                }
            }
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("作り方")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            AsaCard {
                VStack(alignment: .leading, spacing: 16) {
                    let steps = recipe.instructions.components(separatedBy: "\n")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            // ステップ番号
                            ZStack {
                                Circle()
                                    .fill(Color("AsaCoffeeBrown"))
                                    .frame(width: 24, height: 24)
                                
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            // ステップ内容
                            Text(step)
                                .font(.body)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    private var favoriteButton: some View {
        Button(action: {
            viewModel.toggleFavorite(for: recipe)
        }) {
            Image(systemName: viewModel.isFavorite(recipe) ? "heart.fill" : "heart")
                .font(.title2)
                .foregroundColor(viewModel.isFavorite(recipe) ? .red : Color("AsaCoffeeBrown"))
        }
    }
}

#Preview {
    let sampleRecipe = Recipe(
        id: "1",
        title: "チキンカレー",
        image: "https://example.com/image.jpg",
        readyInMinutes: 30,
        servings: 4,
        instructions: "玉ねぎを炒める。\n鶏肉を加えて炒める。\nカレールーを加えて煮込む。",
        ingredients: [
            Ingredient(name: "鶏肉", amount: "300g"),
            Ingredient(name: "玉ねぎ", amount: "1個"),
            Ingredient(name: "カレールー", amount: "1箱")
        ],
        category: "メインディッシュ"
    )
    
    RecipeDetailView(recipe: sampleRecipe, viewModel: RecipeViewModel())
}