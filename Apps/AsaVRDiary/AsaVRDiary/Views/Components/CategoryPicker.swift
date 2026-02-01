//
//  CategoryPicker.swift
//  AsaVRDiary
//
//  カテゴリ選択コンポーネント
//

import SwiftUI

/// カテゴリ選択ピッカー
struct CategoryPicker: View {
    @Binding var selectedCategory: DiaryCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DiaryCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

/// カテゴリボタン
struct CategoryButton: View {
    let category: DiaryCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.subheadline)
                Text(category.displayName)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? category.color : Color(.systemGray6))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

/// カテゴリバッジ（表示用）
struct CategoryBadge: View {
    let category: DiaryCategory
    var showIcon: Bool = true
    var showLabel: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: category.icon)
                    .font(.caption)
            }
            if showLabel {
                Text(category.displayName)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(category.color.opacity(0.15))
        .foregroundStyle(category.color)
        .clipShape(Capsule())
    }
}

/// カテゴリフィルターピッカー（オプショナル選択）
struct CategoryFilterPicker: View {
    @Binding var selectedCategory: DiaryCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // すべて
                Button {
                    selectedCategory = nil
                } label: {
                    Text("すべて")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedCategory == nil ? Color.accentColor : Color(.systemGray6))
                        )
                        .foregroundStyle(selectedCategory == nil ? .white : .primary)
                }
                .buttonStyle(.plain)

                // 各カテゴリ
                ForEach(DiaryCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.caption)
                            Text(category.displayName)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedCategory == category ? category.color : Color(.systemGray6))
                        )
                        .foregroundStyle(selectedCategory == category ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CategoryPicker(selectedCategory: .constant(.daily))

        CategoryFilterPicker(selectedCategory: .constant(.work))

        HStack {
            ForEach([DiaryCategory.daily, .work, .family, .hobby], id: \.self) { category in
                CategoryBadge(category: category)
            }
        }
    }
    .padding()
}
