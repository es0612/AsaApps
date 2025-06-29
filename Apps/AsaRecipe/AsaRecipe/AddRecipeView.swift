//
//  AddRecipeView.swift
//  AsaRecipe
//  
//  Created on 2025/06/30
//

import SwiftUI

struct AddRecipeView: View {
    @Bindable var recipeStore: RecipeStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var recipe = Recipe()
    @State private var newIngredient = ""
    @State private var newInstruction = ""
    
    var body: some View {
        NavigationView {
            Form {
                basicInfoSection
                ingredientsSection
                instructionsSection
                detailsSection
            }
            .navigationTitle("新しいレシピ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        recipeStore.addRecipe(recipe)
                        dismiss()
                    }
                    .disabled(recipe.name.isEmpty)
                }
            }
        }
    }
    
    private var basicInfoSection: some View {
        Section("基本情報") {
            TextField("レシピ名", text: $recipe.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Picker("カテゴリ", selection: $recipe.category) {
                ForEach(RecipeCategory.allCases, id: \.self) { category in
                    HStack {
                        Text(category.icon)
                        Text(category.rawValue)
                    }
                    .tag(category)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private var ingredientsSection: some View {
        Section("材料") {
            ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                HStack {
                    Text("•")
                        .foregroundColor(.asaCoffeeBrown)
                        .fontWeight(.bold)
                    Text(ingredient)
                    Spacer()
                    Button(action: { recipe.ingredients.remove(at: index) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            
            HStack {
                TextField("新しい材料を追加", text: $newIngredient)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: addIngredient) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.asaCoffeeBrown)
                        .font(.title2)
                }
                .disabled(newIngredient.isEmpty)
            }
        }
    }
    
    private var instructionsSection: some View {
        Section("作り方") {
            ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                HStack {
                    Text("\(index + 1).")
                        .foregroundColor(.asaCoffeeBrown)
                        .fontWeight(.bold)
                        .frame(width: 20, alignment: .leading)
                    Text(instruction)
                    Spacer()
                    Button(action: { recipe.instructions.remove(at: index) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            
            HStack {
                TextField("新しい手順を追加", text: $newInstruction)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: addInstruction) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.asaCoffeeBrown)
                        .font(.title2)
                }
                .disabled(newInstruction.isEmpty)
            }
        }
    }
    
    private var detailsSection: some View {
        Section("詳細") {
            HStack {
                Text("調理時間")
                Spacer()
                Stepper(value: $recipe.cookingTime, in: 0...300, step: 5) {
                    Text("\(recipe.cookingTime)分")
                        .foregroundColor(.asaCoffeeBrown)
                        .fontWeight(.medium)
                }
            }
            
            HStack {
                Text("人数")
                Spacer()
                Stepper(value: $recipe.servings, in: 1...20) {
                    Text("\(recipe.servings)人分")
                        .foregroundColor(.asaCoffeeBrown)
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    private func addIngredient() {
        guard !newIngredient.isEmpty else { return }
        recipe.ingredients.append(newIngredient)
        newIngredient = ""
    }
    
    private func addInstruction() {
        guard !newInstruction.isEmpty else { return }
        recipe.instructions.append(newInstruction)
        newInstruction = ""
    }
}

#Preview {
    AddRecipeView(recipeStore: RecipeStore())
}