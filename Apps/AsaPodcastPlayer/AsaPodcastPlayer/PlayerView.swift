//
//  PlayerView.swift
//  AsaPodcastPlayer
//
//  Created by AsaPapa on 2025-10-21.
//

import SwiftUI
import AsaUIKit

struct PlayerView: View {
    // MARK: - Properties

    let episode: PodcastEpisode
    @Bindable var viewModel: PodcastPlayerViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景
            AsaColors.darkSlate
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // エピソード情報カード
                EpisodeDetailView(episode: episode)
                    .padding(.horizontal, 20)

                Spacer()

                // 再生コントロール
                VStack(spacing: 30) {
                    // プログレスバー
                    VStack(spacing: 8) {
                        Slider(
                            value: Binding(
                                get: { viewModel.currentTime },
                                set: { viewModel.seek(to: $0) }
                            ),
                            in: 0...max(viewModel.duration, 0.1)
                        )
                        .accentColor(AsaColors.coffeeBrown)

                        // 時間表示
                        HStack {
                            Text(viewModel.currentTimeFormatted)
                                .font(.caption)
                                .foregroundColor(AsaColors.softCream)

                            Spacer()

                            Text(viewModel.durationFormatted)
                                .font(.caption)
                                .foregroundColor(AsaColors.softCream)
                        }
                    }
                    .padding(.horizontal, 30)

                    // コントロールボタン
                    HStack(spacing: 40) {
                        // 30秒戻るボタン
                        Button(action: viewModel.skipBackward) {
                            Image(systemName: "gobackward.30")
                                .font(.title)
                                .foregroundColor(AsaColors.coffeeBrown)
                        }

                        // 再生/一時停止ボタン
                        Button(action: viewModel.togglePlayPause) {
                            Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(AsaColors.coffeeBrown)
                        }

                        // 30秒進むボタン
                        Button(action: viewModel.skipForward) {
                            Image(systemName: "goforward.30")
                                .font(.title)
                                .foregroundColor(AsaColors.coffeeBrown)
                        }
                    }

                    // 再生速度変更ボタン
                    Button(action: viewModel.nextPlaybackRate) {
                        HStack {
                            Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                                .font(.title3)
                            Text("\(String(format: "%.2f", viewModel.playbackRate))x")
                                .font(.headline)
                        }
                        .foregroundColor(AsaColors.mutedSage)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AsaColors.mocha.opacity(0.3))
                        )
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("再生中")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.selectEpisode(episode)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PlayerView(episode: PodcastEpisode.preview, viewModel: PodcastPlayerViewModel())
    }
}
