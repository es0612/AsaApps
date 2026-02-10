import SwiftUI
import AsaUIKit

// MARK: - 星レーティング表示

/// 0.0-5.0の星レーティングを表示（半星対応）
struct StarRatingView: View {

    // MARK: - Properties

    /// レーティング値（0.0-5.0）
    let rating: Double

    /// 最大星数（デフォルト5）
    let maxStars: Int

    /// 星のサイズ
    var starSize: CGFloat = 20

    /// 星の色
    var filledColor: Color = .yellow

    /// 空の星の色
    var emptyColor: Color = .gray.opacity(0.3)

    // MARK: - Init

    init(rating: Double, maxStars: Int = 5, starSize: CGFloat = 20) {
        self.rating = max(0, min(Double(maxStars), rating))
        self.maxStars = maxStars
        self.starSize = starSize
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<maxStars, id: \.self) { index in
                starImage(for: index)
                    .font(.system(size: starSize))
                    .foregroundColor(starColor(for: index))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("レーティング \(String(format: "%.1f", rating)) / \(maxStars)")
    }

    // MARK: - ヘルパー

    /// インデックスに応じた星アイコンを返す
    private func starImage(for index: Int) -> Image {
        let starValue = Double(index) + 1.0

        if rating >= starValue {
            // 完全に埋まった星
            return Image(systemName: "star.fill")
        } else if rating >= starValue - 0.5 {
            // 半分埋まった星
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            // 空の星
            return Image(systemName: "star")
        }
    }

    /// インデックスに応じた星の色を返す
    private func starColor(for index: Int) -> Color {
        let starValue = Double(index) + 1.0

        if rating >= starValue - 0.5 {
            return filledColor
        } else {
            return emptyColor
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        StarRatingView(rating: 0.0)
        StarRatingView(rating: 1.5)
        StarRatingView(rating: 2.5)
        StarRatingView(rating: 3.0)
        StarRatingView(rating: 4.5)
        StarRatingView(rating: 5.0)
        StarRatingView(rating: 3.7, maxStars: 5, starSize: 30)
    }
    .padding()
}
