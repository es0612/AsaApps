//
//  EpisodeDetailView.swift
//  AsaPodcastPlayer
//
//  Created by AsaPapa on 2025-10-21.
//

import SwiftUI
import AsaUIKit

struct EpisodeDetailView: View {
    // MARK: - Properties

    let episode: PodcastEpisode

    // MARK: - Body

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                // エピソードタイトル
                Text(episode.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AsaColors.coffeeBrown)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                // 公開日
                Text(formatDate(episode.publishedDate))
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)

                Divider()
                    .background(AsaColors.mutedSage.opacity(0.3))

                // エピソード説明
                Text(episode.description)
                    .font(.body)
                    .foregroundColor(AsaColors.softCream)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
            .padding(20)
        }
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }

    // MARK: - Helper Methods

    /// 日付をフォーマット
    /// - Parameter date: フォーマットする日付
    /// - Returns: フォーマットされた文字列
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AsaColors.darkSlate
            .ignoresSafeArea()

        EpisodeDetailView(episode: PodcastEpisode.preview)
            .padding()
    }
}
