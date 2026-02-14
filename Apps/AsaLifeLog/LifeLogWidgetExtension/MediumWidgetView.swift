import SwiftUI
import WidgetKit

// MARK: - MediumWidgetView

/// 中サイズウィジェット: 気分 + 歩数 + 睡眠 + エントリー数
struct MediumWidgetView: View {
    let data: LifeLogWidgetData

    var body: some View {
        HStack(spacing: 16) {
            // 気分
            VStack(spacing: 4) {
                Text(data.moodEmoji ?? "😐")
                    .font(.largeTitle)
                Text(data.moodLabel ?? "未記録")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // 統計
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("\(data.totalSteps)歩", systemImage: "figure.walk")
                        .font(.caption)
                    Spacer()
                    Label(
                        String(format: "%.1fh", data.sleepHours ?? 0),
                        systemImage: "bed.double"
                    )
                    .font(.caption)
                }

                HStack {
                    Label("\(data.entryCount)件", systemImage: "list.bullet")
                        .font(.caption)
                    Spacer()
                    Label("\(data.morningScore)点", systemImage: "sun.max")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}
