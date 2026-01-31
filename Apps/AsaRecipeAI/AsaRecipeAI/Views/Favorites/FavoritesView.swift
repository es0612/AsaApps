//
//  FavoritesView.swift
//  AsaRecipeAI
//
//  お気に入りレシピ一覧
//

import SwiftUI
import AsaUIKit

struct FavoritesView: View {
    // MARK: - Properties

    var viewModel: RecipeAIViewModel

    @State private var selectedRecipe: Recipe?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.favoriteRecipes.isEmpty {
                    emptyStateView
                } else {
                    recipeListView
                }
            }
            .background(Color("AsaSoftCream").opacity(0.3))
            .navigationTitle("お気に入り")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshFavorites()
            }
            .sheet(item: $selectedRecipe) { recipe in
                SavedRecipeDetailView(recipe: recipe, viewModel: viewModel)
            }
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 64))
                .foregroundStyle(Color("AsaMutedSage"))

            Text("お気に入りがありません")
                .font(.headline)
                .foregroundStyle(Color("AsaDarkSlate"))

            Text("レシピを生成して、気に入ったものを\nお気に入りに追加しましょう")
                .font(.subheadline)
                .foregroundStyle(Color("AsaMocha"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Recipe List View

    private var recipeListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.favoriteRecipes) { recipe in
                    SavedRecipeCard(recipe: recipe) {
                        selectedRecipe = recipe
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Saved Recipe Card

struct SavedRecipeCard: View {
    let recipe: Recipe
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color("AsaDarkSlate"))

                        HStack(spacing: 4) {
                            Text(recipe.difficulty.icon)
                            Text(recipe.difficulty.rawValue)
                                .font(.caption)
                                .foregroundStyle(difficultyColor)
                        }
                    }

                    Spacer()

                    if recipe.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(Color("AsaCoffeeBrown"))
                    }
                }

                // 説明
                Text(recipe.recipeDescription)
                    .font(.subheadline)
                    .foregroundStyle(Color("AsaDarkSlate").opacity(0.8))
                    .lineLimit(2)

                // メタ情報
                HStack(spacing: 16) {
                    Label("\(recipe.cookingTimeMinutes)分", systemImage: "clock")
                    Label("\(recipe.servings)人分", systemImage: "person.2")
                    Label("\(recipe.ingredients.count)食材", systemImage: "basket")
                }
                .font(.caption)
                .foregroundStyle(Color("AsaMutedSage"))

                // 調理回数
                if recipe.cookCount > 0 {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(recipe.cookCount)回調理")
                            .font(.caption)
                            .foregroundStyle(Color("AsaMocha"))

                        if let lastCooked = recipe.lastCookedAt {
                            Text("・")
                            Text("最終: \(lastCooked.formatted(.relative(presentation: .named)))")
                                .font(.caption)
                                .foregroundStyle(Color("AsaMutedSage"))
                        }
                    }
                }
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var difficultyColor: Color {
        switch recipe.difficulty {
        case .easy: return .green
        case .normal: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Saved Recipe Detail View

struct SavedRecipeDetailView: View {
    let recipe: Recipe
    var viewModel: RecipeAIViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // ヘッダー
                    headerSection

                    // メタ情報
                    metaSection

                    // 食材
                    ingredientsSection

                    // 調理手順
                    stepsSection

                    // 推薦理由
                    reasonSection

                    // アクションボタン
                    actionSection
                }
                .padding()
            }
            .background(Color("AsaSoftCream").opacity(0.3))
            .navigationTitle(recipe.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recipe.difficulty.icon)
                Text(recipe.difficulty.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(difficultyColor.opacity(0.2))
                    .foregroundStyle(difficultyColor)
                    .clipShape(Capsule())

                Spacer()

                if recipe.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Color("AsaCoffeeBrown"))
                }
            }

            Text(recipe.recipeDescription)
                .font(.body)
                .foregroundStyle(Color("AsaDarkSlate"))
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var metaSection: some View {
        HStack(spacing: 24) {
            VStack {
                Image(systemName: "clock")
                    .font(.title2)
                    .foregroundStyle(Color("AsaCoffeeBrown"))
                Text("\(recipe.cookingTimeMinutes)分")
                    .font(.caption)
                    .foregroundStyle(Color("AsaDarkSlate"))
            }

            VStack {
                Image(systemName: "person.2")
                    .font(.title2)
                    .foregroundStyle(Color("AsaCoffeeBrown"))
                Text("\(recipe.servings)人分")
                    .font(.caption)
                    .foregroundStyle(Color("AsaDarkSlate"))
            }

            VStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text("\(recipe.cookCount)回")
                    .font(.caption)
                    .foregroundStyle(Color("AsaDarkSlate"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("食材")
                .font(.headline)
                .foregroundStyle(Color("AsaDarkSlate"))

            ForEach(recipe.ingredients) { ingredient in
                HStack {
                    Image(systemName: ingredient.isAvailable ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(ingredient.isAvailable ? .green : Color("AsaMutedSage"))

                    Text(ingredient.name)
                        .foregroundStyle(Color("AsaDarkSlate"))

                    Spacer()

                    Text(ingredient.amount)
                        .foregroundStyle(Color("AsaMocha"))
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("調理手順")
                .font(.headline)
                .foregroundStyle(Color("AsaDarkSlate"))

            ForEach(recipe.steps) { step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(step.stepNumber)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color("AsaCoffeeBrown"))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.instruction)
                            .font(.subheadline)
                            .foregroundStyle(Color("AsaDarkSlate"))

                        if let tip = step.tip {
                            HStack(spacing: 4) {
                                Image(systemName: "lightbulb")
                                    .font(.caption2)
                                Text(tip)
                                    .font(.caption)
                            }
                            .foregroundStyle(Color("AsaMocha"))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var reasonSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(Color("AsaCoffeeBrown"))

            Text(recipe.recommendationReason)
                .font(.subheadline)
                .foregroundStyle(Color("AsaMocha"))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("AsaSoftCream"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var actionSection: some View {
        AsaButton(
            title: "🍳 調理完了",
            action: {
                viewModel.markAsCooked(recipe)
                dismiss()
            }
        )
    }

    private var difficultyColor: Color {
        switch recipe.difficulty {
        case .easy: return .green
        case .normal: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    FavoritesView(viewModel: RecipeAIViewModel(
        recipeAIService: RecipeAIService(),
        visionService: VisionService(),
        dataService: DataService(modelContext: try! ModelContainer(for: Recipe.self).mainContext)
    ))
}
