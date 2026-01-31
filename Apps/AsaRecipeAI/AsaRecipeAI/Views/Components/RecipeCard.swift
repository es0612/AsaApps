//
//  RecipeCard.swift
//  AsaRecipeAI
//
//  レシピカードコンポーネント
//

import SwiftUI
import AsaUIKit

struct RecipeCard: View {
    // MARK: - Properties

    let recipe: RecipeRecommendation
    var onFavorite: (() -> Void)?
    var onTap: (() -> Void)?

    @State private var isExpanded = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            headerSection

            // 説明
            Text(recipe.description)
                .font(.subheadline)
                .foregroundStyle(Color("AsaDarkSlate").opacity(0.8))
                .lineLimit(isExpanded ? nil : 2)

            // メタ情報
            metaInfoSection

            // 推薦理由
            HStack(spacing: 4) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundStyle(Color("AsaCoffeeBrown"))

                Text(recipe.recommendationReason)
                    .font(.caption)
                    .foregroundStyle(Color("AsaMocha"))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color("AsaSoftCream"))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // 展開時の詳細
            if isExpanded {
                Divider()
                ingredientsSection
                Divider()
                stepsSection
            }

            // 展開ボタン
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Spacer()
                    Text(isExpanded ? "閉じる" : "詳細を見る")
                        .font(.caption)
                        .fontWeight(.medium)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(Color("AsaCoffeeBrown"))
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("AsaDarkSlate"))

                // 難易度
                HStack(spacing: 4) {
                    Text(difficultyIcon)
                    Text(recipe.difficulty)
                        .font(.caption)
                        .foregroundStyle(difficultyColor)
                }
            }

            Spacer()

            // お気に入りボタン
            if let onFavorite {
                Button(action: onFavorite) {
                    Image(systemName: "heart")
                        .font(.title3)
                        .foregroundStyle(Color("AsaMocha"))
                }
            }
        }
    }

    // MARK: - Meta Info Section

    private var metaInfoSection: some View {
        HStack(spacing: 16) {
            // 調理時間
            Label("\(recipe.cookingTimeMinutes)分", systemImage: "clock")
                .font(.caption)
                .foregroundStyle(Color("AsaMutedSage"))

            // 人数
            Label("\(recipe.servings)人分", systemImage: "person.2")
                .font(.caption)
                .foregroundStyle(Color("AsaMutedSage"))

            // 食材数
            Label("\(recipe.ingredients.count)食材", systemImage: "basket")
                .font(.caption)
                .foregroundStyle(Color("AsaMutedSage"))
        }
    }

    // MARK: - Ingredients Section

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("食材")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color("AsaDarkSlate"))

            ForEach(recipe.ingredients) { ingredient in
                HStack(spacing: 8) {
                    Image(systemName: ingredient.isAvailable ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundStyle(ingredient.isAvailable ? .green : Color("AsaMutedSage"))

                    Text(ingredient.name)
                        .font(.caption)
                        .foregroundStyle(Color("AsaDarkSlate"))

                    Spacer()

                    Text(ingredient.amount)
                        .font(.caption)
                        .foregroundStyle(Color("AsaMocha"))
                }
            }
        }
    }

    // MARK: - Steps Section

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("調理手順")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color("AsaDarkSlate"))

            ForEach(recipe.steps) { step in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(step.stepNumber)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(Color("AsaCoffeeBrown"))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.instruction)
                            .font(.caption)
                            .foregroundStyle(Color("AsaDarkSlate"))

                        if let tip = step.tip {
                            HStack(spacing: 4) {
                                Image(systemName: "lightbulb")
                                    .font(.caption2)
                                Text(tip)
                                    .font(.caption2)
                            }
                            .foregroundStyle(Color("AsaMocha"))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var difficultyIcon: String {
        RecipeDifficulty.from(recipe.difficulty).icon
    }

    private var difficultyColor: Color {
        switch RecipeDifficulty.from(recipe.difficulty) {
        case .easy: return .green
        case .normal: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            RecipeCard(
                recipe: RecipeRecommendation(
                    name: "肉じゃが",
                    description: "家庭の定番料理。ホクホクのじゃがいもと甘辛い味付けが美味しい一品です。",
                    difficulty: "普通",
                    cookingTimeMinutes: 40,
                    servings: 4,
                    ingredients: [
                        RecipeIngredient(name: "じゃがいも", amount: "4個", isAvailable: true),
                        RecipeIngredient(name: "にんじん", amount: "1本", isAvailable: true),
                        RecipeIngredient(name: "玉ねぎ", amount: "1個", isAvailable: true),
                        RecipeIngredient(name: "牛肉", amount: "200g", isAvailable: false),
                    ],
                    steps: [
                        CookingStep(stepNumber: 1, instruction: "野菜を一口大に切る", tip: "じゃがいもは水にさらすとホクホクに"),
                        CookingStep(stepNumber: 2, instruction: "肉を炒める", tip: nil),
                        CookingStep(stepNumber: 3, instruction: "野菜を加えて炒める", tip: nil),
                    ],
                    recommendationReason: "認識した食材で作れる定番料理です"
                ),
                onFavorite: {}
            )
        }
        .padding()
    }
    .background(Color("AsaSoftCream"))
}
