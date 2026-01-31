//
//  AccuracyIndicator.swift
//  AsaLanguageLearn
//
//  発音精度インジケーター
//

import SwiftUI

struct AccuracyIndicator: View {
    let result: PronunciationResult

    var body: some View {
        VStack(spacing: 16) {
            // スコア表示
            ZStack {
                // 背景リング
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)

                // スコアリング
                Circle()
                    .trim(from: 0, to: result.score)
                    .stroke(
                        result.accuracy.color,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: result.score)

                // スコアテキスト
                VStack(spacing: 4) {
                    Text("\(Int(result.score * 100))")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(result.accuracy.color)

                    Text("点")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            // 精度ラベル
            HStack(spacing: 8) {
                Text(result.accuracy.emoji)
                    .font(.title2)

                Text(result.accuracy.displayNameJapanese)
                    .font(.title3.bold())
                    .foregroundColor(result.accuracy.color)
            }

            // フィードバック
            Text(result.feedbackMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

// MARK: - Word Match List

struct WordMatchList: View {
    let wordMatches: [WordMatch]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("単語の認識結果")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            FlowLayout(spacing: 8) {
                ForEach(wordMatches) { match in
                    WordMatchBadge(match: match)
                }
            }
        }
    }
}

struct WordMatchBadge: View {
    let match: WordMatch

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: match.isMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(match.isMatch ? .green : .red)
                .font(.caption)

            Text(match.targetWord)
                .font(.caption)
                .foregroundColor(match.isMatch ? .primary : .secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            match.isMatch
                ? Color.green.opacity(0.1)
                : Color.red.opacity(0.1)
        )
        .clipShape(Capsule())
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
            lineHeight = max(lineHeight, size.height)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

// MARK: - Preview

#Preview {
    let sampleResult = PronunciationResult(
        score: 0.85,
        accuracy: .good,
        normalizedRecognized: "good morning",
        normalizedTarget: "good morning",
        wordMatches: [
            WordMatch(targetWord: "good", recognizedWord: "good", isMatch: true),
            WordMatch(targetWord: "morning", recognizedWord: "morning", isMatch: true),
        ]
    )

    VStack(spacing: 30) {
        AccuracyIndicator(result: sampleResult)

        WordMatchList(wordMatches: sampleResult.wordMatches)
    }
    .padding()
}
