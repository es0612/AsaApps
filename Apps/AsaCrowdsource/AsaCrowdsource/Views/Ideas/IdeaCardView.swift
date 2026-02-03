//
//  IdeaCardView.swift
//  AsaCrowdsource
//
//  アイデアカード表示
//

import SwiftUI
import AsaUIKit

struct IdeaCardView: View {
    // MARK: - Properties

    let idea: Idea

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー（カテゴリ・ステータス）
            HStack {
                // カテゴリバッジ
                Text(idea.category.displayNameWithEmoji)
                    .font(.caption)
                    .foregroundColor(Color(AsaColors.darkSlate))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(AsaColors.softCream))
                    .cornerRadius(4)

                Spacer()

                // ステータスバッジ
                Text(idea.status.displayNameWithEmoji)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .cornerRadius(4)
            }

            // タイトル
            Text(idea.title)
                .font(.headline)
                .foregroundColor(Color(AsaColors.darkSlate))
                .lineLimit(2)

            // 説明（あれば）
            if !idea.ideaDescription.isEmpty {
                Text(idea.ideaDescription)
                    .font(.subheadline)
                    .foregroundColor(Color(AsaColors.mutedSage))
                    .lineLimit(2)
            }

            Divider()

            // フッター（投稿者・統計）
            HStack {
                // 投稿者
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(AsaColors.coffeeBrown).opacity(0.2))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text(String(idea.authorName.prefix(1)))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(Color(AsaColors.coffeeBrown))
                        )

                    Text(idea.authorName)
                        .font(.caption)
                        .foregroundColor(Color(AsaColors.mutedSage))
                }

                Spacer()

                // 統計
                HStack(spacing: 12) {
                    // 投票数
                    HStack(spacing: 4) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.caption)
                        Text("\(idea.voteCount)")
                            .font(.caption)
                    }
                    .foregroundColor(Color(AsaColors.coffeeBrown))

                    // コメント数
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right.fill")
                            .font(.caption)
                        Text("\(idea.commentCount)")
                            .font(.caption)
                    }
                    .foregroundColor(Color(AsaColors.mutedSage))
                }

                // 日付
                Text(formattedDate)
                    .font(.caption2)
                    .foregroundColor(Color(AsaColors.mutedSage))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    // MARK: - Computed Properties

    private var statusColor: Color {
        switch idea.status {
        case .proposed:
            return Color(AsaColors.mutedSage)
        case .discussing:
            return Color(AsaColors.coffeeBrown)
        case .approved:
            return Color.green.opacity(0.8)
        case .inProgress:
            return Color.orange
        case .completed:
            return Color.green
        case .archived:
            return Color.gray
        }
    }

    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: idea.createdAt, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ForEach(Idea.sampleIdeas) { idea in
            IdeaCardView(idea: idea)
        }
    }
    .padding()
    .background(Color(AsaColors.softCream).opacity(0.3))
}
