import SwiftUI
import AsaLifeLogKit

// MARK: - PatternCard

/// パターン検出結果カード
struct PatternCard: View {
    let pattern: PatternResult

    var body: some View {
        AsaLifeLogCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .foregroundStyle(.purple)

                    Text(pattern.patternType)
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    // 信頼度
                    Text("\(Int(pattern.confidence * 100))%")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(confidenceColor.opacity(0.15))
                        .foregroundStyle(confidenceColor)
                        .clipShape(Capsule())
                }

                Text(pattern.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !pattern.relatedTags.isEmpty {
                    HStack {
                        ForEach(pattern.relatedTags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.purple.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private var confidenceColor: Color {
        switch pattern.confidence {
        case 0.7...: return .green
        case 0.4..<0.7: return .orange
        default: return .red
        }
    }
}
