//
//  MoodPicker.swift
//  AsaVRDiary
//
//  気分選択コンポーネント
//

import SwiftUI

/// 気分選択ピッカー
struct MoodPicker: View {
    @Binding var selectedMood: DiaryMood
    @Binding var intensity: Int

    var body: some View {
        VStack(spacing: 16) {
            // 気分選択グリッド
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(DiaryMood.allCases, id: \.self) { mood in
                    MoodButton(
                        mood: mood,
                        isSelected: selectedMood == mood,
                        action: { selectedMood = mood }
                    )
                }
            }

            // 強度スライダー
            VStack(spacing: 8) {
                HStack {
                    Text("強度")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(intensity)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Slider(value: Binding(
                    get: { Double(intensity) },
                    set: { intensity = Int($0) }
                ), in: 1...5, step: 1)
                .tint(selectedMood.color)

                HStack {
                    Text("弱い")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("強い")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

/// 気分ボタン
struct MoodButton: View {
    let mood: DiaryMood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.title)

                Text(mood.displayName)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? mood.color.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? mood.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

/// 気分表示バッジ
struct MoodBadge: View {
    let mood: DiaryMood
    var showLabel: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            Text(mood.emoji)
            if showLabel {
                Text(mood.displayName)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(mood.color.opacity(0.15))
        .foregroundStyle(mood.color)
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 20) {
        MoodPicker(
            selectedMood: .constant(.happy),
            intensity: .constant(3)
        )

        HStack {
            ForEach([DiaryMood.veryHappy, .happy, .neutral, .sad], id: \.self) { mood in
                MoodBadge(mood: mood)
            }
        }
    }
    .padding()
}
