import SwiftUI
import AsaUIKit

struct PriceLabel: View {
    let price: Double
    let originalPrice: Double?
    let size: PriceLabelSize

    init(price: Double, originalPrice: Double? = nil, size: PriceLabelSize = .medium) {
        self.price = price
        self.originalPrice = originalPrice
        self.size = size
    }

    var body: some View {
        HStack(spacing: size.spacing) {
            Text("¥\(Int(price).formatted())")
                .font(size.priceFont)
                .fontWeight(.bold)
                .foregroundColor(AsaColors.coffeeBrown)

            if let original = originalPrice, original > price {
                Text("¥\(Int(original).formatted())")
                    .font(size.originalFont)
                    .strikethrough()
                    .foregroundColor(AsaColors.mutedSage)

                let discount = Int(((original - price) / original) * 100)
                Text("-\(discount)%")
                    .font(size.discountFont)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.8))
                    .clipShape(Capsule())
            }
        }
    }
}

enum PriceLabelSize {
    case small
    case medium
    case large

    var priceFont: Font {
        switch self {
        case .small: return .subheadline
        case .medium: return .title3
        case .large: return .title
        }
    }

    var originalFont: Font {
        switch self {
        case .small: return .caption2
        case .medium: return .caption
        case .large: return .subheadline
        }
    }

    var discountFont: Font {
        switch self {
        case .small: return .caption2
        case .medium: return .caption
        case .large: return .subheadline
        }
    }

    var spacing: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PriceLabel(price: 3980, originalPrice: 4980, size: .small)
        PriceLabel(price: 3980, originalPrice: 4980, size: .medium)
        PriceLabel(price: 3980, originalPrice: 4980, size: .large)
        PriceLabel(price: 2480, size: .medium)
    }
    .padding()
}
