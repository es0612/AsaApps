//
//  StreamingTextView.swift
//  AsaRecipeAI
//
//  ストリーミングテキスト表示コンポーネント
//  LLMからのリアルタイム応答を表示
//

import SwiftUI
import FoundationModels

struct StreamingTextView: View {
    // MARK: - Properties

    let text: String
    let isStreaming: Bool

    @State private var displayedText = ""
    @State private var cursorVisible = true

    // MARK: - Body

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Text(text)
                .font(.body)
                .foregroundStyle(Color("AsaDarkSlate"))

            if isStreaming {
                Rectangle()
                    .fill(Color("AsaCoffeeBrown"))
                    .frame(width: 2, height: 16)
                    .opacity(cursorVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(), value: cursorVisible)
                    .onAppear {
                        cursorVisible = true
                    }
            }
        }
    }
}

// MARK: - Streaming Recipe View

/// ストリーミング中のレシピ表示
struct StreamingRecipeView: View {
    let partialRecipes: RecipeRecommendations.PartiallyGenerated?
    let isGenerating: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let recipes = partialRecipes?.recipes {
                ForEach(recipes.indices, id: \.self) { index in
                    if let recipe = recipes[index] {
                        StreamingRecipeCard(recipe: recipe, index: index)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            ))
                    }
                }
            }

            if isGenerating {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(Color("AsaCoffeeBrown"))

                    Text("レシピを生成中...")
                        .font(.caption)
                        .foregroundStyle(Color("AsaMocha"))
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: partialRecipes?.recipes?.count)
    }
}

// MARK: - Streaming Recipe Card

/// ストリーミング中のレシピカード
struct StreamingRecipeCard: View {
    let recipe: RecipeRecommendation.PartiallyGenerated
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // レシピ名
            if let name = recipe.name {
                HStack {
                    Text("\(index + 1). \(name)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("AsaDarkSlate"))

                    Spacer()

                    // 難易度
                    if let difficulty = recipe.difficulty {
                        Text(difficulty)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(difficultyColor(difficulty).opacity(0.2))
                            .foregroundStyle(difficultyColor(difficulty))
                            .clipShape(Capsule())
                    }
                }
            } else {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("レシピ \(index + 1) を生成中...")
                        .font(.subheadline)
                        .foregroundStyle(Color("AsaMocha"))
                }
            }

            // 説明
            if let description = recipe.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(Color("AsaDarkSlate").opacity(0.8))
                    .lineLimit(3)
            }

            // メタ情報
            HStack(spacing: 12) {
                if let time = recipe.cookingTimeMinutes {
                    Label("\(time)分", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(Color("AsaMutedSage"))
                }

                if let servings = recipe.servings {
                    Label("\(servings)人分", systemImage: "person.2")
                        .font(.caption)
                        .foregroundStyle(Color("AsaMutedSage"))
                }

                if let ingredients = recipe.ingredients {
                    let count = ingredients.compactMap { $0 }.count
                    Label("\(count)食材", systemImage: "basket")
                        .font(.caption)
                        .foregroundStyle(Color("AsaMutedSage"))
                }
            }

            // 食材プレビュー（生成中）
            if let ingredients = recipe.ingredients {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ingredients.indices, id: \.self) { i in
                            if let ing = ingredients[i] {
                                HStack(spacing: 4) {
                                    Image(systemName: ing.isAvailable == true ? "checkmark.circle.fill" : "circle")
                                        .font(.caption2)
                                        .foregroundStyle(ing.isAvailable == true ? .green : .gray)
                                    Text(ing.name ?? "")
                                        .font(.caption2)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color("AsaSoftCream"))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            // 推薦理由
            if let reason = recipe.recommendationReason {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption2)
                        .foregroundStyle(Color("AsaCoffeeBrown"))

                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(Color("AsaMocha"))
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty {
        case "簡単": return .green
        case "普通": return .orange
        case "上級": return .red
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        StreamingTextView(
            text: "これはストリーミングテキストのサンプルです",
            isStreaming: true
        )
        .padding()

        StreamingRecipeCard(
            recipe: RecipeRecommendation.PartiallyGenerated(),
            index: 0
        )
        .padding()
    }
    .background(Color("AsaSoftCream"))
}
