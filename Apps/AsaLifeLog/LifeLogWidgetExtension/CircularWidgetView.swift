import SwiftUI
import WidgetKit

// MARK: - CircularWidgetView

/// 円形ウィジェット（accessoryCircular）: 朝活スコアゲージ
struct CircularWidgetView: View {
    let data: LifeLogWidgetData

    private var progress: Double {
        Double(data.morningScore) / 100.0
    }

    var body: some View {
        Gauge(value: progress) {
            Image(systemName: "sun.max")
        } currentValueLabel: {
            Text("\(data.morningScore)")
                .font(.system(.body, design: .rounded, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
    }
}
