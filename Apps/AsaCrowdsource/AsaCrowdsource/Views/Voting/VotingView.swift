//
//  VotingView.swift
//  AsaCrowdsource
//
//  投票コンポーネント
//

import SwiftUI
import AsaUIKit

struct VotingView: View {
    // MARK: - Properties

    let voteSummary: VoteSummary
    let userVote: Vote?
    let onVote: (VoteType) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // 投票ボタン
            HStack(spacing: 12) {
                ForEach(VoteType.allCases) { voteType in
                    VoteButton(
                        voteType: voteType,
                        count: voteCount(for: voteType),
                        isSelected: userVote?.type == voteType
                    ) {
                        onVote(voteType)
                    }
                }
            }

            // 投票サマリー
            if voteSummary.totalCount > 0 {
                voteSummaryBar
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Subviews

    private var voteSummaryBar: some View {
        VStack(spacing: 8) {
            // 合計
            HStack {
                Text("合計 \(voteSummary.totalCount) 票")
                    .font(.caption)
                    .foregroundColor(Color(AsaColors.mutedSage))

                Spacer()

                Text("スコア: \(voteSummary.weightedScore)")
                    .font(.caption)
                    .foregroundColor(Color(AsaColors.coffeeBrown))
            }

            // プログレスバー
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    if voteSummary.loveCount > 0 {
                        Rectangle()
                            .fill(Color.red.opacity(0.7))
                            .frame(width: barWidth(for: voteSummary.loveCount, total: voteSummary.totalCount, in: geometry))
                    }

                    if voteSummary.likeCount > 0 {
                        Rectangle()
                            .fill(Color(AsaColors.coffeeBrown))
                            .frame(width: barWidth(for: voteSummary.likeCount, total: voteSummary.totalCount, in: geometry))
                    }

                    if voteSummary.interestedCount > 0 {
                        Rectangle()
                            .fill(Color(AsaColors.mutedSage))
                            .frame(width: barWidth(for: voteSummary.interestedCount, total: voteSummary.totalCount, in: geometry))
                    }
                }
                .frame(height: 8)
                .cornerRadius(4)
            }
            .frame(height: 8)
        }
    }

    // MARK: - Private Methods

    private func voteCount(for type: VoteType) -> Int {
        switch type {
        case .like: return voteSummary.likeCount
        case .love: return voteSummary.loveCount
        case .interested: return voteSummary.interestedCount
        }
    }

    private func barWidth(for count: Int, total: Int, in geometry: GeometryProxy) -> CGFloat {
        guard total > 0 else { return 0 }
        let totalWidth = geometry.size.width - CGFloat(2 * (voteSummary.totalCount - 1)) // spacing考慮
        return totalWidth * CGFloat(count) / CGFloat(total)
    }
}

// MARK: - Vote Button

struct VoteButton: View {
    let voteType: VoteType
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(voteType.emoji)
                    .font(.title2)

                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.medium)

                Text(voteType.displayName)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? buttonColor.opacity(0.2) : Color(AsaColors.softCream).opacity(0.5))
            .foregroundColor(isSelected ? buttonColor : Color(AsaColors.darkSlate))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? buttonColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private var buttonColor: Color {
        switch voteType {
        case .like: return Color(AsaColors.coffeeBrown)
        case .love: return Color.red
        case .interested: return Color(AsaColors.mutedSage)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // 投票なし
        VotingView(
            voteSummary: .empty,
            userVote: nil
        ) { _ in }

        // 投票あり
        VotingView(
            voteSummary: VoteSummary(likeCount: 3, loveCount: 2, interestedCount: 1),
            userVote: Vote(type: .like, ideaId: UUID(), userId: "user1", userName: "テスト")
        ) { _ in }
    }
    .padding()
    .background(Color(AsaColors.softCream).opacity(0.3))
}
