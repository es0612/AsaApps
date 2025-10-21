//
//  PodcastLibraryView.swift
//  AsaPodcastPlayer
//
//  Created by AsaPapa on 2025-10-21.
//

import SwiftUI
import AsaUIKit

struct PodcastLibraryView: View {
    // MARK: - Properties

    @Bindable var viewModel: PodcastPlayerViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景色
            AsaColors.darkSlate
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダー
                headerView

                // エピソード一覧
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(PodcastEpisode.sampleEpisodes) { episode in
                            NavigationLink(value: episode) {
                                EpisodeListRow(episode: episode)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationDestination(for: PodcastEpisode.self) { episode in
            PlayerView(episode: episode, viewModel: viewModel)
        }
    }

    // MARK: - Subviews

    /// ヘッダービュー
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("朝活パパのポッドキャスト")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AsaColors.softCream)

            Text("\(PodcastEpisode.sampleEpisodes.count)件のエピソード")
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AsaColors.coffeeBrown.opacity(0.3))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PodcastLibraryView(viewModel: PodcastPlayerViewModel())
    }
}
