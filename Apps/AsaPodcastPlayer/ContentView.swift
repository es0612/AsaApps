import SwiftUI

struct ContentView: View {
    @State private var viewModel = PodcastPlayerViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color("AsaSoftCream"), Color("AsaDarkSlate").opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerView

                    // Scrollable Content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Current Episode Section
                            if let currentEpisode = viewModel.currentEpisode {
                                currentEpisodeView(episode: currentEpisode, geometry: geometry)
                            } else {
                                noEpisodeSelectedView
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 240) // プレーヤーコントロールの高さ分の余白
                    }

                    Spacer()

                    // Player Controls (fixed at bottom)
                    playerControlsSection
                        .background(
                            Color.white.opacity(0.95)
                                .cornerRadius(20, corners: [.topLeft, .topRight])
                                .shadow(radius: 10)
                        )
                }
            }
        }
        .sheet(isPresented: $viewModel.showingLibrary) {
            PodcastLibraryView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingEpisodeDetail) {
            if let episode = viewModel.currentEpisode {
                EpisodeDetailView(episode: episode, viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.loadPodcastLibrary()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AsaPodcastPlayer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Text("朝活パパのポッドキャストプレイヤー")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Sleep Timer Button
                Button(action: showSleepTimerSettings) {
                    Image(systemName: viewModel.sleepTimerEnabled ? "moon.fill" : "moon")
                        .font(.title2)
                        .foregroundColor(viewModel.sleepTimerEnabled ? Color("AsaCoffeeBrown") : .secondary)
                        .padding(12)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                
                // Library Button
                Button(action: viewModel.showLibrary) {
                    Image(systemName: "list.bullet")
                        .font(.title2)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .padding(12)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Current Episode View

    private func currentEpisodeView(episode: PodcastEpisode, geometry: GeometryProxy) -> some View {
        let artworkSize = min(geometry.size.width * 0.5, 220) // 画面幅の50%、最大220pt

        return VStack(spacing: 16) {
            // Episode Artwork
            episodeArtworkView(episode: episode, size: artworkSize)

            // Episode Info
            episodeInfoView(episode: episode)

            // Progress Info
            episodeProgressView(episode: episode)
        }
    }

    private func episodeArtworkView(episode: PodcastEpisode, size: CGFloat) -> some View {
        Button(action: { viewModel.showEpisodeDetail(for: episode) }) {
            Group {
                if let artwork = episode.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: size * 0.3))
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .frame(width: size, height: size)
                        .background(Color("AsaSoftCream"))
                }
            }
            .frame(width: size, height: size)
            .cornerRadius(20)
            .shadow(radius: 10)
            .overlay(
                // Play state indicator
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        viewModel.playerState == .playing ? Color("AsaCoffeeBrown") : Color.clear,
                        lineWidth: 3
                    )
                    .animation(.easeInOut(duration: 0.3), value: viewModel.playerState)
            )
        }
    }
    
    private func episodeInfoView(episode: PodcastEpisode) -> some View {
        VStack(spacing: 8) {
            Text(episode.displayTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color("AsaCoffeeBrown"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(episode.podcastName)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if !episode.displayDescription.isEmpty {
                Text(episode.displayDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal)
            }
        }
    }
    
    private func episodeProgressView(episode: PodcastEpisode) -> some View {
        VStack(spacing: 12) {
            // Time info
            HStack {
                Text(viewModel.currentTime == 0 ? episode.formattedPlaybackPosition : formatTime(viewModel.currentTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if viewModel.sleepTimerEnabled {
                    HStack(spacing: 4) {
                        Image(systemName: "moon.fill")
                            .font(.caption)
                        Text(viewModel.formattedSleepTimerRemainingTime)
                            .font(.caption)
                    }
                    .foregroundColor(Color("AsaMocha"))
                }
                
                Spacer()
                
                Text(episode.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            ProgressView(value: viewModel.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color("AsaCoffeeBrown")))
                .background(Color("AsaMutedSage").opacity(0.3))
                .cornerRadius(4)
            
            // Playback rate indicator
            if viewModel.playbackRate != 1.0 {
                HStack {
                    Image(systemName: "speedometer")
                        .font(.caption)
                    Text(viewModel.formattedPlaybackRate)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(Color("AsaMocha"))
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - No Episode View
    
    private var noEpisodeSelectedView: some View {
        VStack(spacing: 30) {
            Image(systemName: "mic")
                .font(.system(size: 100))
                .foregroundColor(Color("AsaMutedSage"))
            
            VStack(spacing: 12) {
                Text("ポッドキャストを選択してください")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Text("ライブラリからエピソードを選んで\nポッドキャストを楽しみましょう")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("ライブラリを開く") {
                viewModel.showLibrary()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(Color("AsaCoffeeBrown"))
            .cornerRadius(25)
            .shadow(radius: 5)
        }
    }
    
    // MARK: - Player Controls Section
    
    private var playerControlsSection: some View {
        VStack(spacing: 24) {
            // Main playback controls
            HStack(spacing: 40) {
                // Skip backward
                Button(action: viewModel.skipBackward) {
                    VStack(spacing: 6) {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 32))
                            .fontWeight(.semibold)
                        Text("15秒")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(viewModel.currentEpisode != nil ? Color("AsaDarkSlate") : .gray.opacity(0.3))
                }
                .disabled(viewModel.currentEpisode == nil)

                // Previous episode
                Button(action: viewModel.previousEpisode) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 28))
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.hasPreviousEpisode ? Color("AsaDarkSlate") : .secondary)
                }
                .disabled(!viewModel.hasPreviousEpisode)
                
                // Play/Pause
                Button(action: viewModel.togglePlayPause) {
                    ZStack {
                        // ローディング時のプログレスインジケーター
                        if viewModel.playerState == .loading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(Color("AsaCoffeeBrown"))
                        } else {
                            Image(systemName: viewModel.playerState == .playing ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(viewModel.currentEpisode != nil ? Color("AsaCoffeeBrown") : .gray.opacity(0.3))
                                .shadow(color: Color("AsaCoffeeBrown").opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                    }
                    .frame(width: 60, height: 60)
                }
                .disabled(viewModel.currentEpisode == nil || viewModel.playerState == .loading)
                .scaleEffect(viewModel.playerState == .playing ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: viewModel.playerState)
                
                // Next episode
                Button(action: viewModel.nextEpisode) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 28))
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.hasNextEpisode ? Color("AsaDarkSlate") : .secondary)
                }
                .disabled(!viewModel.hasNextEpisode)

                // Skip forward
                Button(action: viewModel.skipForward) {
                    VStack(spacing: 6) {
                        Image(systemName: "goforward.30")
                            .font(.system(size: 32))
                            .fontWeight(.semibold)
                        Text("30秒")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(viewModel.currentEpisode != nil ? Color("AsaDarkSlate") : .gray.opacity(0.3))
                }
                .disabled(viewModel.currentEpisode == nil)
            }
            
            // Additional controls
            HStack(spacing: 30) {
                // Playback rate
                Button(action: viewModel.nextPlaybackRate) {
                    VStack(spacing: 6) {
                        Text(viewModel.formattedPlaybackRate)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("再生速度")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(viewModel.playbackRate != 1.0 ? Color("AsaCoffeeBrown") : Color("AsaDarkSlate"))
                }
                .disabled(viewModel.currentEpisode == nil)

                Spacer()

                // Auto play next
                Button(action: { viewModel.autoPlayNext.toggle() }) {
                    VStack(spacing: 6) {
                        Image(systemName: viewModel.autoPlayNext ? "repeat" : "repeat.1")
                            .font(.system(size: 24))
                            .fontWeight(.semibold)
                        Text("自動再生")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(viewModel.autoPlayNext ? Color("AsaCoffeeBrown") : Color("AsaDarkSlate"))
                }

                Spacer()

                // Volume control indicator
                Button(action: {}) {
                    VStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 24))
                            .fontWeight(.semibold)
                        Text("音量")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Color("AsaDarkSlate").opacity(0.6))
                }
                .disabled(true) // Volume controlled by system
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
        .padding(.top, 20)
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let time = max(0, timeInterval)
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private func showSleepTimerSettings() {
        // TODO: Implement sleep timer settings
        let sleepDuration: TimeInterval = 15 * 60 // 15 minutes
        if viewModel.sleepTimerEnabled {
            viewModel.cancelSleepTimer()
        } else {
            viewModel.setSleepTimer(duration: sleepDuration)
        }
    }
}

// MARK: - Custom Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .preferredColorScheme(.light)
}