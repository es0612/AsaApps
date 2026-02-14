import SwiftUI
import AsaLifeLogKit

// MARK: - MoodBadge

/// 気分スコアの絵文字バッジ
struct MoodBadge: View {
    let mood: MoodScore

    var body: some View {
        Text(mood.emoji)
            .font(.title2)
            .padding(6)
            .background(backgroundColor)
            .clipShape(Circle())
    }

    private var backgroundColor: Color {
        switch mood {
        case .terrible: return .red.opacity(0.15)
        case .bad: return .orange.opacity(0.15)
        case .neutral: return .gray.opacity(0.15)
        case .good: return .green.opacity(0.15)
        case .great: return .yellow.opacity(0.15)
        }
    }
}
