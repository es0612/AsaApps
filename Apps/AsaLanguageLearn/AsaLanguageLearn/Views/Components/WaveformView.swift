//
//  WaveformView.swift
//  AsaLanguageLearn
//
//  音声波形表示
//

import SwiftUI

struct WaveformView: View {
    let audioLevel: Float
    let isActive: Bool
    let barCount: Int

    @State private var levels: [Float] = []

    init(audioLevel: Float, isActive: Bool, barCount: Int = 20) {
        self.audioLevel = audioLevel
        self.isActive = isActive
        self.barCount = barCount
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: index))
                    .frame(width: 4, height: barHeight(for: index))
                    .animation(.easeOut(duration: 0.1), value: levels)
            }
        }
        .frame(height: 40)
        .onChange(of: audioLevel) { _, newValue in
            updateLevels(with: newValue)
        }
        .onAppear {
            levels = Array(repeating: 0.1, count: barCount)
        }
    }

    private func updateLevels(with newLevel: Float) {
        guard isActive else {
            levels = Array(repeating: 0.1, count: barCount)
            return
        }

        // 新しいレベルを追加して古いものを削除
        var newLevels = levels
        newLevels.append(newLevel)
        if newLevels.count > barCount {
            newLevels.removeFirst()
        }
        levels = newLevels
    }

    private func barHeight(for index: Int) -> CGFloat {
        let level: Float
        if index < levels.count {
            level = levels[index]
        } else {
            level = 0.1
        }

        // 最小高さ4、最大高さ40
        let height = CGFloat(level) * 36 + 4
        return min(40, max(4, height))
    }

    private func barColor(for index: Int) -> Color {
        if !isActive {
            return Color.gray.opacity(0.3)
        }

        let level: Float = index < levels.count ? levels[index] : 0
        if level > 0.7 {
            return Color("AsaCoffeeBrown")
        } else if level > 0.4 {
            return Color("AsaMocha")
        } else {
            return Color("AsaMutedSage")
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        WaveformView(audioLevel: 0.3, isActive: true)
        WaveformView(audioLevel: 0.7, isActive: true)
        WaveformView(audioLevel: 0, isActive: false)
    }
    .padding()
}
