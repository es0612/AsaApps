import SwiftUI
import AsaLifeLogKit

// MARK: - PhotoTimelineView

/// 写真タイムラインビュー
struct PhotoTimelineView: View {
    let entries: [LifeLogEntry]

    private var photoEntries: [LifeLogEntry] {
        entries.filter { $0.entryType == .photo || !$0.photoAssetIdentifiers.isEmpty }
    }

    var body: some View {
        if photoEntries.isEmpty {
            EmptyStateView(
                icon: "photo.on.rectangle.angled",
                title: "写真なし",
                message: "タイムラインに写真を追加すると、ここに表示されます"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(photoEntries, id: \.id) { entry in
                        AsaLifeLogCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(entry.title)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Text("\(entry.photoAssetIdentifiers.count)枚の写真")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if let location = entry.locationName {
                                    Label(location, systemImage: "mappin")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}
