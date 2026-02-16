import SwiftUI
import Charts
import AsaUIKit

// MARK: - 月次支出チャート

/// 月次の支出カテゴリ別チャート
struct MonthlySpendingChart: View {
    // サンプル支出データ
    private let spending: [(String, Double, Color)] = [
        ("食費", 65000, .orange),
        ("住居費", 120000, .blue),
        ("光熱費", 18000, .green),
        ("交通費", 15000, .purple),
        ("教育費", 35000, .pink),
        ("その他", 25000, .gray),
    ]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今月の支出")
                    .font(.headline)
                Spacer()
                Text("合計: \(formattedTotal)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            Chart {
                ForEach(spending, id: \.0) { item in
                    SectorMark(
                        angle: .value("金額", item.1),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(item.2)
                    .annotation(position: .overlay) {
                        Text(item.0)
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                    }
                }
            }
            .frame(height: 200)

            // 凡例
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 8) {
                ForEach(spending, id: \.0) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(item.2)
                            .frame(width: 8, height: 8)
                        Text(item.0)
                            .font(.caption)
                        Spacer()
                        Text(formatYen(item.1))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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

    private var formattedTotal: String {
        formatYen(spending.reduce(0) { $0 + $1.1 })
    }

    private func formatYen(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0円"
    }
}
