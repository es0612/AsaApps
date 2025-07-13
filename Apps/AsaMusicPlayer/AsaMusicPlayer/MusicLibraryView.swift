import SwiftUI

struct MusicLibraryView: View {
    @ObservedObject var viewModel: MusicPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                searchBar
                
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredTracks.isEmpty {
                    emptyLibraryView
                } else {
                    musicListView
                }
            }
            .navigationTitle("音楽ライブラリ")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        viewModel.hideLibrary()
                        dismiss()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("更新") {
                        viewModel.loadMusicLibrary()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("楽曲、アーティストを検索...", text: $viewModel.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color("AsaCoffeeBrown"))
            
            Text("音楽ライブラリを読み込み中...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyLibraryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("音楽が見つかりません")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Documents/Musicフォルダに音楽ファイルを追加してください")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("ライブラリを更新") {
                viewModel.loadMusicLibrary()
            }
            .padding()
            .background(Color("AsaCoffeeBrown"))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var musicListView: some View {
        List(viewModel.filteredTracks) { track in
            MusicTrackRowView(
                track: track,
                isCurrentTrack: viewModel.currentTrack?.id == track.id,
                isPlaying: viewModel.playerState.isPlaying && viewModel.currentTrack?.id == track.id
            ) {
                viewModel.playTrack(track)
            } onAddToPlaylist: {
                viewModel.addToPlaylist(track)
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct MusicTrackRowView: View {
    let track: MusicTrack
    let isCurrentTrack: Bool
    let isPlaying: Bool
    let onPlay: () -> Void
    let onAddToPlaylist: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            artworkView
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.displayTitle)
                    .font(.headline)
                    .foregroundColor(isCurrentTrack ? Color("AsaCoffeeBrown") : .primary)
                    .lineLimit(1)
                
                Text(track.displayArtist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if let album = track.album, !album.isEmpty {
                    Text(album)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(track.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                playButton
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onPlay()
        }
        .contextMenu {
            contextMenuItems
        }
    }
    
    private var artworkView: some View {
        Group {
            if let artwork = track.artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "music.note")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 50, height: 50)
        .background(Color("AsaSoftCream"))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrentTrack ? Color("AsaCoffeeBrown") : Color.clear, lineWidth: 2)
        )
    }
    
    private var playButton: some View {
        Button(action: onPlay) {
            Image(systemName: playButtonIcon)
                .font(.title3)
                .foregroundColor(Color("AsaCoffeeBrown"))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var playButtonIcon: String {
        if isCurrentTrack && isPlaying {
            return "pause.circle.fill"
        } else {
            return "play.circle.fill"
        }
    }
    
    private var contextMenuItems: some View {
        VStack {
            Button(action: onPlay) {
                Label("再生", systemImage: "play.fill")
            }
            
            Button(action: onAddToPlaylist) {
                Label("プレイリストに追加", systemImage: "plus")
            }
        }
    }
}

#Preview {
    @StateObject var viewModel = MusicPlayerViewModel()
    
    return MusicLibraryView(viewModel: viewModel)
        .background(Color("AsaSoftCream"))
}