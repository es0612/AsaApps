//
//  ContentView.swift
//  AsaRecipe
//  
//  Created on 2025/06/30
//

import SwiftUI

struct ContentView: View {
    @State private var recipeStore = RecipeStore()
    
    var body: some View {
        RecipeListView(recipeStore: recipeStore)
            .tint(.asaCoffeeBrown)
    }
}

#Preview {
    ContentView()
}
