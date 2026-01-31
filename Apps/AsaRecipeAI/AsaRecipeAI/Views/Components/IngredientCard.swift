//
//  IngredientCard.swift
//  AsaRecipeAI
//
//  食材カードコンポーネント
//

import SwiftUI

struct IngredientCard: View {
    // MARK: - Properties

    let ingredient: IngredientInfo

    // MARK: - Body

    var body: some View {
        VStack(spacing: 4) {
            Text(ingredient.emoji)
                .font(.system(size: 32))

            Text(ingredient.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color("AsaDarkSlate"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // 信頼度インジケーター
            HStack(spacing: 2) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(index < Int(ingredient.confidence * 5) ?
                              categoryColor : Color.gray.opacity(0.3))
                        .frame(width: 4, height: 4)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(categoryColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(categoryColor.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Computed Properties

    private var categoryColor: Color {
        let category = IngredientCategory.from(ingredient.category)
        switch category {
        case .vegetable: return .green
        case .meat: return .red
        case .seafood: return .blue
        case .dairy: return .yellow
        case .grain: return .orange
        case .seasoning: return .purple
        case .egg: return .orange
        case .tofu: return .brown
        case .fruit: return .pink
        case .other: return .gray
        }
    }
}

// MARK: - Saved Ingredient Card

/// 保存された食材用カード
struct SavedIngredientCard: View {
    let ingredient: SavedIngredient

    var body: some View {
        HStack(spacing: 8) {
            Text(ingredient.emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color("AsaDarkSlate"))

                Text(ingredient.category)
                    .font(.caption2)
                    .foregroundStyle(Color("AsaMutedSage"))
            }

            Spacer()

            // 信頼度
            Text("\(Int(ingredient.confidence * 100))%")
                .font(.caption)
                .foregroundStyle(Color("AsaMocha"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            IngredientCard(ingredient: IngredientInfo(
                name: "にんじん",
                category: "野菜",
                confidence: 0.95,
                emoji: "🥕"
            ))

            IngredientCard(ingredient: IngredientInfo(
                name: "鶏もも肉",
                category: "肉類",
                confidence: 0.88,
                emoji: "🍗"
            ))

            IngredientCard(ingredient: IngredientInfo(
                name: "卵",
                category: "卵",
                confidence: 0.99,
                emoji: "🥚"
            ))
        }

        SavedIngredientCard(ingredient: SavedIngredient(
            name: "玉ねぎ",
            category: "野菜",
            confidence: 0.92,
            emoji: "🧅"
        ))
    }
    .padding()
    .background(Color("AsaSoftCream"))
}
