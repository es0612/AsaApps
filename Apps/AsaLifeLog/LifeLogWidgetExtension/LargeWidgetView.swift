import SwiftUI
import WidgetKit

// MARK: - LargeWidgetView

/// 大サイズウィジェット: 本日タイムライン要約
struct LargeWidgetView: View {
    let data: LifeLogWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ヘッダー
            HStack {
                Text("今日のライフログ")
                    .font(.headline)
                Spacer()
                Text(data.moodEmoji ?? "😐")
                    .font(.title2)
            }

            // 統計サマリー
            HStack(spacing: 16) {
                StatItem(icon: "figure.walk", value: "\(data.totalSteps)", label: "歩数")
                StatItem(icon: "bed.double", value: String(format: "%.1fh", data.sleepHours ?? 0), label: "睡眠")
                StatItem(icon: "sun.max", value: "\(data.morningScore)", label: "朝活")
                StatItem(icon: "list.bullet", value: "\(data.entryCount)", label: "記録")
            }

            Divider()

            // 直近エントリー
            if data.recentEntries.isEmpty {
                Text("今日のエントリーはまだありません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(data.recentEntries.prefix(5)) { entry in
                    HStack(spacing: 8) {
                        Image(systemName: entry.icon)
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 20)

                        Text(entry.title)
                            .font(.caption)
                            .lineLimit(1)

                        Spacer()

                        Text(entry.time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - StatItem

/// ウィジェット用統計項目
private struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.bold))
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
