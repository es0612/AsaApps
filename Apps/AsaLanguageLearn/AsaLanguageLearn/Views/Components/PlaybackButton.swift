//
//  PlaybackButton.swift
//  AsaLanguageLearn
//
//  再生ボタン（模範発音再生）
//

import SwiftUI

struct PlaybackButton: View {
    let isPlaying: Bool
    let progress: Double
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 進捗リング
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color("AsaCoffeeBrown"),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)

                // 背景
                Circle()
                    .fill(Color("AsaSoftCream"))

                // アイコン
                Image(systemName: isPlaying ? "pause.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color("AsaCoffeeBrown"))
            }
            .frame(width: 50, height: 50)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Speed Button

struct SpeedButton: View {
    let currentPreset: SpeechRatePreset
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: currentPreset.icon)
                    .font(.system(size: 12))
                Text(currentPreset.displayMultiplier)
                    .font(.caption.bold())
            }
            .foregroundColor(Color("AsaCoffeeBrown"))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color("AsaSoftCream"))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        PlaybackButton(isPlaying: false, progress: 0, onTap: {})
        PlaybackButton(isPlaying: true, progress: 0.6, onTap: {})

        HStack(spacing: 10) {
            ForEach(SpeechRatePreset.allCases, id: \.displayMultiplier) { preset in
                SpeedButton(currentPreset: preset, onTap: {})
            }
        }
    }
    .padding()
}
