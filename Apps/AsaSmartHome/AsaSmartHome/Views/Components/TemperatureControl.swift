import SwiftUI

// MARK: - TemperatureControl

/// エアコン温度調整コントロール（+-ボタン付き）
struct TemperatureControl: View {
    // MARK: - Properties

    @Binding var temperature: Int
    let minTemp: Int
    let maxTemp: Int
    let onChanged: (Int) async -> Void

    @State private var isUpdating = false

    // MARK: - Initialization

    init(
        temperature: Binding<Int>,
        minTemp: Int = 16,
        maxTemp: Int = 30,
        onChanged: @escaping (Int) async -> Void
    ) {
        self._temperature = temperature
        self.minTemp = minTemp
        self.maxTemp = maxTemp
        self.onChanged = onChanged
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            // 温度表示
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(temperature)")
                    .font(.system(size: 64, weight: .light, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                Text("°C")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.6))
            }

            // +-ボタン
            HStack(spacing: 40) {
                Button {
                    decreaseTemperature()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(temperature > minTemp ? Color.asaCoffeeBrown : Color.white.opacity(0.3))
                }
                .disabled(temperature <= minTemp || isUpdating)

                Button {
                    increaseTemperature()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(temperature < maxTemp ? Color.asaCoffeeBrown : Color.white.opacity(0.3))
                }
                .disabled(temperature >= maxTemp || isUpdating)
            }

            // 範囲表示
            Text("\(minTemp)°C 〜 \(maxTemp)°C")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Private Methods

    private func increaseTemperature() {
        guard temperature < maxTemp else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            temperature += 1
        }
        updateTemperature()
    }

    private func decreaseTemperature() {
        guard temperature > minTemp else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            temperature -= 1
        }
        updateTemperature()
    }

    private func updateTemperature() {
        isUpdating = true
        Task {
            await onChanged(temperature)
            isUpdating = false
        }
    }
}

// MARK: - ChannelControl

/// テレビチャンネル調整コントロール
struct ChannelControl: View {
    // MARK: - Properties

    @Binding var channel: Int
    let onChanged: (Int) async -> Void

    @State private var isUpdating = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            Text("チャンネル")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 24) {
                Button {
                    decreaseChannel()
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.asaCoffeeBrown)
                }
                .disabled(channel <= 1 || isUpdating)

                Text("\(channel)")
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(minWidth: 60)
                    .contentTransition(.numericText())

                Button {
                    increaseChannel()
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.asaCoffeeBrown)
                }
                .disabled(isUpdating)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Private Methods

    private func increaseChannel() {
        withAnimation(.easeInOut(duration: 0.2)) {
            channel += 1
        }
        updateChannel()
    }

    private func decreaseChannel() {
        guard channel > 1 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            channel -= 1
        }
        updateChannel()
    }

    private func updateChannel() {
        isUpdating = true
        Task {
            await onChanged(channel)
            isUpdating = false
        }
    }
}

// MARK: - Preview

#Preview("Temperature Control") {
    VStack(spacing: 24) {
        TemperatureControl(temperature: .constant(24), onChanged: { _ in })
        ChannelControl(channel: .constant(5), onChanged: { _ in })
    }
    .padding()
    .background(Color.asaDarkSlate)
}
