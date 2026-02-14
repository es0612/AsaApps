import SwiftUI
import WidgetKit

// MARK: - SmallWidgetView

/// 小サイズウィジェット: 気分 + エントリー数 + 朝活スコア
struct SmallWidgetView: View {
    let data: LifeLogWidgetData

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(data.moodEmoji ?? "😐")
                    .font(.title)
                Spacer()
                Text("\(data.morningScore)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.orange)
            }

            Spacer()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("記録")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(data.entryCount)")
                        .font(.subheadline.weight(.semibold))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("朝活")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(data.morningScore)点")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}
