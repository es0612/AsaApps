import SwiftUI

struct PodcastLibraryView: View {
    @Bindable var viewModel: PodcastPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPodcast: Podcast?
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal)
                
                // Podcast list
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredPodcasts.isEmpty {
                    emptyStateView
                } else {
                    podcastListView
                }
                
                Spacer()
            }
            .navigationTitle("ポッドキャストライブラリ")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
            .sheet(item: $selectedPodcast) { podcast in
                EpisodeListView(podcast: podcast, viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color("AsaCoffeeBrown")))
                .scaleEffect(1.5)
            
            Text("ポッドキャストを読み込み中...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(Color("AsaMutedSage"))
            
            Text("ポッドキャストが見つかりません")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            if !viewModel.searchText.isEmpty {
                Text("「\(viewModel.searchText)」に一致するポッドキャストがありません")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("購読しているポッドキャストがありません")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    // MARK: - Podcast List View
    
    private var podcastListView: some View {
        List {
            ForEach(viewModel.filteredPodcasts) { podcast in
                PodcastRowView(
                    podcast: podcast,
                    action: {
                        selectedPodcast = podcast
                        viewModel.selectPodcast(podcast)
                    }
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("ポッドキャストを検索", text: $text)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color("AsaSoftCream").opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Podcast Row View

struct PodcastRowView: View {
    let podcast: Podcast
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Podcast artwork
                Group {
                    if let artwork = podcast.artwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color("AsaCoffeeBrown"))
                            .frame(width: 60, height: 60)
                            .background(Color("AsaSoftCream"))
                    }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(12)
                .shadow(radius: 2)
                
                // Podcast info
                VStack(alignment: .leading, spacing: 4) {
                    Text(podcast.displayName)
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .lineLimit(2)
                    
                    Text(podcast.displayAuthor)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.caption)
                            Text("\(podcast.totalEpisodes)話")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        if podcast.unplayedEpisodes > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                Text("\(podcast.unplayedEpisodes)未再生")
                                    .font(.caption)
                            }
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Episode List View

struct EpisodeListView: View {
    let podcast: Podcast
    @Bindable var viewModel: PodcastPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(podcast.episodes) { episode in
                    EpisodeRowView(
                        episode: episode,
                        isCurrentlyPlaying: viewModel.currentEpisode?.id == episode.id,
                        action: {
                            viewModel.playEpisode(episode)
                            dismiss()
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle(podcast.displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
        }
    }
}

// MARK: - Episode Row View

struct EpisodeRowView: View {
    let episode: PodcastEpisode
    let isCurrentlyPlaying: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Play status indicator
                ZStack {
                    Circle()
                        .fill(isCurrentlyPlaying ? Color("AsaCoffeeBrown") : Color("AsaMutedSage").opacity(0.3))
                        .frame(width: 32, height: 32)
                    
                    if isCurrentlyPlaying {
                        Image(systemName: "waveform")
                            .font(.caption)
                            .foregroundColor(.white)
                    } else if episode.isPlayed {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.white)
                    } else if episode.playbackPosition > 0 {
                        Circle()
                            .fill(Color("AsaCoffeeBrown"))
                            .frame(width: 8, height: 8)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Episode info
                VStack(alignment: .leading, spacing: 4) {
                    Text(episode.displayTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .lineLimit(2)
                    
                    Text(episode.formattedPublishDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(episode.formattedDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if episode.playbackPosition > 0 && !episode.isPlayed {
                            Text("• \(episode.formattedPlaybackPosition)から")
                                .font(.caption)
                                .foregroundColor(Color("AsaMocha"))
                        }
                    }
                    
                    // Progress bar for partially played episodes
                    if episode.playbackPosition > 0 && !episode.isPlayed {
                        ProgressView(value: episode.playbackProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color("AsaCoffeeBrown")))
                            .frame(height: 2)
                    }
                }
                
                Spacer()
                
                // Bookmark indicator
                if episode.isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                        .foregroundColor(Color("AsaMocha"))
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

