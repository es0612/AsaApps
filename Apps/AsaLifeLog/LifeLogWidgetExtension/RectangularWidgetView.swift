import SwiftUI
import WidgetKit

// MARK: - RectangularWidgetView

/// 長方形ウィジェット（accessoryRectangular）: 歩数 + 気分
struct RectangularWidgetView: View {
    let data: LifeLogWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(data.moodEmoji ?? "😐")
                Text("AsaLifeLog")
                    .font(.headline)
                    .widgetAccentable()
            }

            HStack(spacing: 12) {
                Label("\(data.totalSteps)歩", systemImage: "figure.walk")
                    .font(.caption)

                Label("\(data.morningScore)点", systemImage: "sun.max")
                    .font(.caption)
            }
        }
    }
}
