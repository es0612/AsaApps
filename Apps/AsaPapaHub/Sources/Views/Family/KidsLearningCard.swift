import SwiftUI
import AsaUIKit

// MARK: - 子供の学習カード

/// 子供の学習進捗を表示するカード
struct KidsLearningCard: View {
    // サンプルデータ
    private let learningItems: [(String, Double, String)] = [
        ("算数ドリル", 0.8, "function"),
        ("国語の読み取り", 0.6, "text.book.closed"),
        ("英語フラッシュカード", 0.45, "globe"),
    ]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("子供の学習")
                .font(.headline)

            ForEach(learningItems, id: \.0) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: item.2)
                            .font(.caption)
                            .foregroundStyle(.indigo)
                        Text(item.0)
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(item.1 * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(AsaColors.coffeeBrown)
                    }

                    ProgressView(value: item.1)
                        .tint(.indigo)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
    }
}
