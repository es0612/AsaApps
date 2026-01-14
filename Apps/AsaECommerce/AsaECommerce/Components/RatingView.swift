import SwiftUI
import AsaUIKit

struct RatingView: View {
    let rating: Double
    let reviewCount: Int
    let showCount: Bool

    init(rating: Double, reviewCount: Int = 0, showCount: Bool = true) {
        self.rating = rating
        self.reviewCount = reviewCount
        self.showCount = showCount
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: starImageName(for: index))
                    .font(.caption)
                    .foregroundColor(.yellow)
            }

            if showCount && reviewCount > 0 {
                Text("(\(reviewCount))")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
        }
    }

    private func starImageName(for index: Int) -> String {
        let value = rating - Double(index)
        if value >= 1 {
            return "star.fill"
        } else if value >= 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        RatingView(rating: 4.8, reviewCount: 256)
        RatingView(rating: 3.5, reviewCount: 100)
        RatingView(rating: 2.0, reviewCount: 50)
        RatingView(rating: 4.5, showCount: false)
    }
    .padding()
}
