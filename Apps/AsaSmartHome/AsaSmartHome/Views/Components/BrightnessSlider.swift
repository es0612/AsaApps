import SwiftUI

// MARK: - BrightnessSlider

/// 明るさ調整スライダー
struct BrightnessSlider: View {
    // MARK: - Properties

    @Binding var value: Double
    let range: ClosedRange<Double>
    let label: String
    let icon: String
    let valueFormatter: (Double) -> String
    let onChanged: (Int) async -> Void

    @State private var isDragging = false

    // MARK: - Initialization

    init(
        value: Binding<Double>,
        range: ClosedRange<Double> = 0...100,
        label: String = "明るさ",
        icon: String = "sun.max.fill",
        valueFormatter: @escaping (Double) -> String = { "\(Int($0))%" },
        onChanged: @escaping (Int) async -> Void
    ) {
        self._value = value
        self.range = range
        self.label = label
        self.icon = icon
        self.valueFormatter = valueFormatter
        self.onChanged = onChanged
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.asaCoffeeBrown)

                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.white)

                Spacer()

                Text(valueFormatter(value))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.8))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景トラック
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    // 進捗バー
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.asaCoffeeBrown)
                        .frame(
                            width: max(0, progressWidth(in: geometry.size.width)),
                            height: 8
                        )

                    // つまみ
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .offset(x: thumbOffset(in: geometry.size.width))
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isDragging)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            isDragging = true
                            updateValue(from: gesture.location.x, width: geometry.size.width)
                        }
                        .onEnded { _ in
                            isDragging = false
                            Task {
                                await onChanged(Int(value))
                            }
                        }
                )
            }
            .frame(height: 24)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Private Methods

    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        let percentage = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return totalWidth * percentage
    }

    private func thumbOffset(in totalWidth: CGFloat) -> CGFloat {
        let percentage = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return max(0, min(totalWidth - 24, totalWidth * percentage - 12))
    }

    private func updateValue(from x: CGFloat, width: CGFloat) {
        let percentage = max(0, min(1, x / width))
        let newValue = range.lowerBound + (range.upperBound - range.lowerBound) * percentage
        value = newValue
    }
}

// MARK: - TemperatureSlider

/// 温度調整スライダー
struct TemperatureSlider: View {
    @Binding var value: Double
    let onChanged: (Int) async -> Void

    var body: some View {
        BrightnessSlider(
            value: $value,
            range: 16...30,
            label: "設定温度",
            icon: "thermometer.medium",
            valueFormatter: { "\(Int($0))°C" },
            onChanged: onChanged
        )
    }
}

// MARK: - VolumeSlider

/// 音量調整スライダー
struct VolumeSlider: View {
    @Binding var value: Double
    let onChanged: (Int) async -> Void

    var body: some View {
        BrightnessSlider(
            value: $value,
            range: 0...100,
            label: "音量",
            icon: "speaker.wave.2.fill",
            valueFormatter: { "\(Int($0))%" },
            onChanged: onChanged
        )
    }
}

// MARK: - ColorTemperatureSlider

/// 色温度調整スライダー
struct ColorTemperatureSlider: View {
    @Binding var value: Double
    let onChanged: (Int) async -> Void

    var body: some View {
        BrightnessSlider(
            value: $value,
            range: 2700...6500,
            label: "色温度",
            icon: "circle.lefthalf.filled",
            valueFormatter: { "\(Int($0))K" },
            onChanged: onChanged
        )
    }
}

// MARK: - CurtainSlider

/// カーテン開度スライダー
struct CurtainSlider: View {
    @Binding var value: Double
    let onChanged: (Int) async -> Void

    var body: some View {
        BrightnessSlider(
            value: $value,
            range: 0...100,
            label: "開度",
            icon: "blinds.vertical.closed",
            valueFormatter: { "\(Int($0))%" },
            onChanged: onChanged
        )
    }
}

// MARK: - Preview

#Preview("Sliders") {
    VStack(spacing: 16) {
        BrightnessSlider(value: .constant(75), onChanged: { _ in })
        TemperatureSlider(value: .constant(24), onChanged: { _ in })
        VolumeSlider(value: .constant(50), onChanged: { _ in })
        ColorTemperatureSlider(value: .constant(4000), onChanged: { _ in })
    }
    .padding()
    .background(Color.asaDarkSlate)
}
