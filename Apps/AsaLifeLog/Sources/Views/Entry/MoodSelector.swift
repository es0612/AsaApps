import SwiftUI
import AsaLifeLogKit

// MARK: - MoodSelector

/// 気分選択ビュー（5段階の絵文字ボタン）
struct MoodSelector: View {
    @Binding var selectedMood: MoodScore?

    var body: some View {
        HStack(spacing: 16) {
            ForEach(MoodScore.allCases, id: \.self) { mood in
                Button {
                    if selectedMood == mood {
                        selectedMood = nil
                    } else {
                        selectedMood = mood
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(mood.emoji)
                            .font(.title)
                            .scaleEffect(selectedMood == mood ? 1.2 : 1.0)

                        Text(mood.displayName)
                            .font(.caption2)
                            .foregroundStyle(selectedMood == mood ? .primary : .secondary)
                    }
                    .padding(8)
                    .background(
                        selectedMood == mood ? Color.accentColor.opacity(0.15) : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: selectedMood)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
