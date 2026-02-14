import SwiftUI
import AsaLifeLogKit

// MARK: - TimelineEntryRow

/// タイムラインの個別エントリー行
struct TimelineEntryRow: View {
    let entry: LifeLogEntry
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void

    private var timeText: String {
        entry.timestamp.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        AsaLifeLogCard {
            HStack(spacing: 12) {
                // ソースアイコン
                Image(systemName: entry.entryType.icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                    .frame(width: 36, height: 36)
                    .background(iconColor.opacity(0.12))
                    .clipShape(Circle())

                // コンテンツ
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)

                        Spacer()

                        Text(timeText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let content = entry.content, !content.isEmpty {
                        Text(content)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 6) {
                        // 気分バッジ
                        if let mood = entry.moodScore {
                            Text(mood.emoji)
                                .font(.caption)
                        }

                        // ソースバッジ
                        Text(entry.source.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary)
                            .clipShape(Capsule())

                        // タグ
                        ForEach(entry.tags.prefix(2), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }

                        Spacer()

                        // お気に入り
                        if entry.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                    }
                }
            }
        }
        .contextMenu {
            Button {
                onToggleFavorite()
            } label: {
                Label(
                    entry.isFavorite ? "お気に入り解除" : "お気に入り",
                    systemImage: entry.isFavorite ? "star.slash" : "star"
                )
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }

    private var iconColor: Color {
        switch entry.entryType {
        case .manual: return .blue
        case .health: return .red
        case .location: return .green
        case .photo: return .purple
        case .activity: return .orange
        case .mood: return .yellow
        }
    }
}
