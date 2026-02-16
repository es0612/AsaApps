import SwiftUI
import AsaUIKit

// MARK: - 家族イベントカード

/// 今後の家族イベントを表示するカード
struct FamilyEventCard: View {
    // サンプルイベントデータ
    private let events: [(String, String, String)] = [
        ("子供の習い事", "15:00", "figure.run"),
        ("家族ディナー", "18:30", "fork.knife"),
        ("週末のお出かけ（土）", "10:00", "car.fill"),
    ]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今後のイベント")
                .font(.headline)

            ForEach(events, id: \.0) { event in
                HStack(spacing: 12) {
                    Image(systemName: event.2)
                        .font(.body)
                        .foregroundStyle(.purple)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle().fill(.purple.opacity(0.1))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.0)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(event.1)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
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
