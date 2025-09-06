import SwiftUI

struct EpisodeDetailView: View {
    let episode: PodcastEpisode
    @Bindable var viewModel: PodcastPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Episode artwork and basic info
                    episodeHeaderView
                    
                    // Episode metadata
                    episodeMetadataView
                    
                    // Episode description
                    episodeDescriptionView
                    
                    // Playback controls
                    playbackControlsView
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("エピソード詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("戻る") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: toggleBookmark) {
                            Label(
                                episode.isBookmarked ? "ブックマークを削除" : "ブックマークに追加",
                                systemImage: episode.isBookmarked ? "bookmark.slash" : "bookmark"
                            )
                        }
                        
                        Button(action: togglePlayedStatus) {
                            Label(
                                episode.isPlayed ? "未再生にマーク" : "再生済みにマーク",
                                systemImage: episode.isPlayed ? "circle" : "checkmark.circle"
                            )
                        }
                        
                        if episode.playbackPosition > 0 {
                            Button(action: resetProgress) {
                                Label("進捗をリセット", systemImage: "arrow.counterclockwise")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
        }
    }
    
    // MARK: - Episode Header View
    
    private var episodeHeaderView: some View {
        VStack(spacing: 16) {
            // Artwork
            Group {
                if let artwork = episode.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .frame(width: 200, height: 200)
                        .background(Color("AsaSoftCream"))
                }
            }
            .frame(width: 200, height: 200)
            .cornerRadius(20)
            .shadow(radius: 10)
            
            // Title and podcast name
            VStack(spacing: 8) {
                Text(episode.displayTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .multilineTextAlignment(.center)
                
                Text(episode.podcastName)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if !episode.author.isEmpty {
                    Text("by \(episode.author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    // MARK: - Episode Metadata View
    
    private var episodeMetadataView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("エピソード情報")
                .font(.headline)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            VStack(spacing: 8) {
                metadataRow(
                    icon: "calendar",
                    title: "公開日",
                    value: episode.formattedPublishDate
                )
                
                metadataRow(
                    icon: "clock",
                    title: "再生時間",
                    value: episode.formattedDuration
                )
                
                if let episodeNumber = episode.episodeNumber {
                    metadataRow(
                        icon: "number",
                        title: "エピソード番号",
                        value: "第\(episodeNumber)話"
                    )
                }
                
                if episode.playbackPosition > 0 {
                    metadataRow(
                        icon: "play.circle",
                        title: "再生位置",
                        value: episode.formattedPlaybackPosition
                    )
                }
                
                if episode.isBookmarked {
                    metadataRow(
                        icon: "bookmark.fill",
                        title: "ブックマーク",
                        value: "保存済み",
                        valueColor: Color("AsaMocha")
                    )
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func metadataRow(
        icon: String,
        title: String,
        value: String,
        valueColor: Color = .secondary
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Color("AsaMocha"))
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(valueColor)
        }
    }
    
    // MARK: - Episode Description View
    
    private var episodeDescriptionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("エピソード概要")
                .font(.headline)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            if !episode.displayDescription.isEmpty {
                Text(episode.displayDescription)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(4)
            } else {
                Text("このエピソードには概要がありません。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Playback Controls View
    
    private var playbackControlsView: some View {
        VStack(spacing: 16) {
            Text("再生コントロール")
                .font(.headline)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            // Progress bar (if episode is partially played)
            if episode.playbackPosition > 0 {
                VStack(spacing: 8) {
                    HStack {
                        Text("進捗")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(episode.playbackProgress * 100))% 完了")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMocha"))
                    }
                    
                    ProgressView(value: episode.playbackProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color("AsaCoffeeBrown")))
                        .background(Color("AsaMutedSage").opacity(0.3))
                        .cornerRadius(4)
                }
            }
            
            // Play/Continue button
            Button(action: playEpisode) {
                HStack(spacing: 12) {
                    Image(systemName: getPlayButtonIcon())
                        .font(.title2)
                    
                    Text(getPlayButtonText())
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 16)
                .background(Color("AsaCoffeeBrown"))
                .cornerRadius(25)
                .shadow(radius: 5)
            }
            
            // Additional controls
            HStack(spacing: 20) {
                Button(action: playFromBeginning) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                        Text("最初から")
                            .font(.caption)
                    }
                    .foregroundColor(Color("AsaMocha"))
                }
                
                Spacer()
                
                Button(action: toggleBookmark) {
                    VStack(spacing: 4) {
                        Image(systemName: episode.isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.title2)
                        Text("ブックマーク")
                            .font(.caption)
                    }
                    .foregroundColor(episode.isBookmarked ? Color("AsaCoffeeBrown") : Color("AsaMocha"))
                }
                
                Spacer()
                
                Button(action: togglePlayedStatus) {
                    VStack(spacing: 4) {
                        Image(systemName: episode.isPlayed ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                        Text(episode.isPlayed ? "再生済み" : "未再生")
                            .font(.caption)
                    }
                    .foregroundColor(episode.isPlayed ? Color("AsaCoffeeBrown") : Color("AsaMocha"))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Helper Methods
    
    private func getPlayButtonIcon() -> String {
        if viewModel.currentEpisode?.id == episode.id {
            return viewModel.playerState == .playing ? "pause.circle.fill" : "play.circle.fill"
        } else if episode.playbackPosition > 0 {
            return "play.circle.fill"
        } else {
            return "play.circle.fill"
        }
    }
    
    private func getPlayButtonText() -> String {
        if viewModel.currentEpisode?.id == episode.id {
            return viewModel.playerState == .playing ? "一時停止" : "再生"
        } else if episode.playbackPosition > 0 {
            return "続きから再生"
        } else {
            return "再生"
        }
    }
    
    private func playEpisode() {
        if viewModel.currentEpisode?.id == episode.id {
            viewModel.togglePlayPause()
        } else {
            viewModel.playEpisode(episode)
        }
        dismiss()
    }
    
    private func playFromBeginning() {
        var modifiedEpisode = episode
        modifiedEpisode.updatePlaybackPosition(0)
        modifiedEpisode.markAsUnplayed()
        viewModel.playEpisode(modifiedEpisode)
        dismiss()
    }
    
    private func toggleBookmark() {
        viewModel.toggleEpisodeBookmark(episode)
    }
    
    private func togglePlayedStatus() {
        if episode.isPlayed {
            viewModel.markEpisodeAsUnplayed(episode)
        } else {
            viewModel.markEpisodeAsPlayed(episode)
        }
    }
    
    private func resetProgress() {
        viewModel.markEpisodeAsUnplayed(episode)
    }
}

// MARK: - Preview

#Preview {
    EpisodeDetailView(
        episode: PodcastEpisode(
            title: "Sample Episode",
            description: "This is a sample episode description that demonstrates how the episode detail view looks with longer text content.",
            duration: 1800,
            filePath: URL(fileURLWithPath: "/tmp/sample.mp3"),
            podcastName: "Sample Podcast",
            author: "Sample Author",
            playbackPosition: 600,
            isBookmarked: true,
            episodeNumber: 1
        ),
        viewModel: PodcastPlayerViewModel()
    )
}