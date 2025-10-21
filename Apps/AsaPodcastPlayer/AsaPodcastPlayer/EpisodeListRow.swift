//
//  EpisodeListRow.swift
//  AsaPodcastPlayer
//
//  Created by AsaPapa on 2025-10-21.
//

import SwiftUI
import AsaUIKit

struct EpisodeListRow: View {
    // MARK: - Properties

    let episode: PodcastEpisode

    // MARK: - Body

    var body: some View {
        AsaCard {
            HStack(spacing: 16) {
                // エピソード情報
                VStack(alignment: .leading, spacing: 8) {
                    // タイトル
                    Text(episode.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AsaColors.coffeeBrown)
                        .lineLimit(2)

                    // 説明
                    Text(episode.description)
                        .font(.caption)
                        .foregroundColor(AsaColors.softCream)
                        .lineLimit(2)

                    // メタ情報
                    HStack(spacing: 12) {
                        // 公開日
                        Label(
                            formatDate(episode.publishedDate),
                            systemImage: "calendar"
                        )
                        .font(.caption2)
                        .foregroundColor(AsaColors.mutedSage)

                        // 再生時間
                        Label(
                            formatDuration(episode.duration),
                            systemImage: "clock"
                        )
                        .font(.caption2)
                        .foregroundColor(AsaColors.mutedSage)
                    }
                }

                Spacer()

                // 再生アイコン
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AsaColors.coffeeBrown)
            }
            .padding(16)
        }
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Helper Methods

    /// 日付をフォーマット
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    /// 再生時間をフォーマット（MM:SS）
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AsaColors.darkSlate
            .ignoresSafeArea()

        VStack(spacing: 16) {
            EpisodeListRow(episode: PodcastEpisode.sampleEpisodes[0])
            EpisodeListRow(episode: PodcastEpisode.sampleEpisodes[1])
            EpisodeListRow(episode: PodcastEpisode.sampleEpisodes[2])
        }
        .padding()
    }
}
