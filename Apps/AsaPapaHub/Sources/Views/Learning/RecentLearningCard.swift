import SwiftUI
import AsaUIKit

// MARK: - 最近の学習カード

/// 最近の学習アクティビティを表示するカード
struct RecentLearningCard: View {
    // サンプルデータ
    private let learningItems: [(String, String, String, Int)] = [
        ("SwiftUI 100本ノック", "book.fill", "プログラミング", 30),
        ("英語フラッシュカード", "globe", "英語", 15),
        ("TOEIC単語帳", "character.book.closed.fill", "英語", 10),
        ("Swift Concurrency", "swift", "プログラミング", 20),
    ]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近の学習")
                    .font(.headline)
                Spacer()
                Text("合計: \(totalMinutes)分")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(AsaColors.coffeeBrown)
            }

            ForEach(learningItems, id: \.0) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.1)
                        .font(.body)
                        .foregroundStyle(.purple)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.purple.opacity(0.1))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.0)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(item.2)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(item.3)分")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AsaColors.mutedSage)
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

    // MARK: - Private

    private var totalMinutes: Int {
        learningItems.reduce(0) { $0 + $1.3 }
    }
}
