import SwiftUI
import AsaUIKit

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.subheadline)

                Text(category.name)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? AsaColors.coffeeBrown : AsaColors.softCream)
            .foregroundColor(isSelected ? .white : AsaColors.darkSlate)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        CategoryChip(category: Category.defaultCategories[0], isSelected: true, action: {})
        CategoryChip(category: Category.defaultCategories[1], isSelected: false, action: {})
    }
    .padding()
}
