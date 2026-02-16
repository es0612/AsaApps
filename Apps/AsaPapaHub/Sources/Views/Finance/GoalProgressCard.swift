import SwiftUI
import AsaUIKit

// MARK: - 目標進捗カード

/// 資産目標の進捗を表示するカード
struct GoalProgressCard: View {
    // サンプル目標データ
    private let goals: [(String, Double, String, Color)] = [
        ("緊急資金", 0.75, "180万 / 240万円", .green),
        ("教育資金", 0.45, "270万 / 600万円", .blue),
        ("住宅ローン返済", 0.62, "1,860万 / 3,000万円", .orange),
    ]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("資産目標")
                .font(.headline)

            ForEach(goals, id: \.0) { goal in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(goal.0)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(Int(goal.1 * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(goal.3)
                    }

                    ProgressView(value: goal.1)
                        .tint(goal.3)

                    Text(goal.2)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
