import SwiftUI
import Charts
import AsaUIKit
import AsaCommunityKit

/// コミュニティ分析チャートコンポーネント
struct CommunityAnalyticsChart: View {
    let posts: [CommunityPost]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("投稿カテゴリ分布")
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)

            let data = CommunityAnalytics.postCountByCategory(posts: posts)

            if data.isEmpty {
                Text("データなし")
                    .foregroundStyle(.secondary)
            } else {
                Chart(data, id: \.category) { item in
                    BarMark(
                        x: .value("カテゴリ", item.category.rawValue),
                        y: .value("件数", item.count)
                    )
                    .foregroundStyle(AsaColors.coffeeBrown)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
