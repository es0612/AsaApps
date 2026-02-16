import SwiftUI
import AsaUIKit

// MARK: - 地域イベントカード

/// 地域イベントの一覧表示カード
struct LocalEventCard: View {
    // サンプルイベントデータ
    private let events: [(String, String, String, String)] = [
        ("防災訓練", "2月22日 10:00", "shield.checkered", "市役所前広場"),
        ("子育て交流会", "2月25日 14:00", "person.3.fill", "コミュニティセンター"),
        ("朝活ランニング", "毎週土曜 6:30", "figure.run", "中央公園"),
    ]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("地域イベント")
                    .font(.headline)
                Spacer()
                Text("\(events.count)件")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(events, id: \.0) { event in
                HStack(spacing: 12) {
                    Image(systemName: event.2)
                        .font(.body)
                        .foregroundStyle(.blue)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.blue.opacity(0.1))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.0)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(event.1)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.caption2)
                            Text(event.3)
                                .font(.caption)
                        }
                        .foregroundStyle(.tertiary)
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
