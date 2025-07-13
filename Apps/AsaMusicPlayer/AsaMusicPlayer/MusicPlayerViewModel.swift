import Foundation
import Combine

@MainActor
class MusicPlayerViewModel: ObservableObject {
    @Published var currentPlaylist: [MusicTrack] = []
    @Published var currentTrackIndex: Int = 0
    @Published var searchText: String = ""
    @Published var showingLibrary: Bool = false
    
    private let audioManager: AudioManager
    private let libraryManager: MusicLibraryManager
    private var cancellables = Set<AnyCancellable>()
    
    var currentTrack: MusicTrack? {
        guard currentTrackIndex >= 0 && currentTrackIndex < currentPlaylist.count else {
            return nil
        }
        return currentPlaylist[currentTrackIndex]
    }
    
    var playerState: MusicPlayerState {
        audioManager.playerState
    }
    
    var currentTime: TimeInterval {
        audioManager.currentTime
    }
    
    var duration: TimeInterval {
        audioManager.duration
    }
    
    var volume: Float {
        get { audioManager.volume }
        set { audioManager.volume = newValue }
    }
    
    var shuffleEnabled: Bool {
        get { audioManager.shuffleEnabled }
        set { audioManager.shuffleEnabled = newValue }
    }
    
    var repeatMode: RepeatMode {
        get { audioManager.repeatMode }
        set { audioManager.repeatMode = newValue }
    }
    
    var progress: Double {
        audioManager.progress
    }
    
    var isLoading: Bool {
        libraryManager.isLoading
    }
    
    var filteredTracks: [MusicTrack] {
        if searchText.isEmpty {
            return libraryManager.musicTracks
        } else {
            return libraryManager.searchTracks(query: searchText)
        }
    }
    
    var hasNextTrack: Bool {
        switch repeatMode {
        case .one:
            return true
        case .all:
            return !currentPlaylist.isEmpty
        case .none:
            return currentTrackIndex < currentPlaylist.count - 1
        }
    }
    
    var hasPreviousTrack: Bool {
        switch repeatMode {
        case .one:
            return true
        case .all:
            return !currentPlaylist.isEmpty
        case .none:
            return currentTrackIndex > 0
        }
    }
    
    init(audioManager: AudioManager = AudioManager(), libraryManager: MusicLibraryManager = MusicLibraryManager()) {
        self.audioManager = audioManager
        self.libraryManager = libraryManager
        
        setupBindings()
        loadMusicLibrary()
    }
    
    private func setupBindings() {
        audioManager.$currentTrack
            .sink { [weak self] track in
                if let track = track {
                    self?.updateCurrentTrackIndex(for: track)
                }
            }
            .store(in: &cancellables)
        
        audioManager.$playerState
            .sink { [weak self] state in
                if state == .stopped {
                    self?.handleTrackFinished()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadMusicLibrary() {
        libraryManager.loadMusicLibrary()
    }
    
    func playTrack(_ track: MusicTrack) {
        audioManager.loadTrack(track)
        audioManager.play()
        
        if !currentPlaylist.contains(track) {
            currentPlaylist = [track]
            currentTrackIndex = 0
        } else {
            updateCurrentTrackIndex(for: track)
        }
    }
    
    func playPlaylist(_ tracks: [MusicTrack], startingAt index: Int = 0) {
        guard !tracks.isEmpty && index >= 0 && index < tracks.count else { return }
        
        currentPlaylist = tracks
        currentTrackIndex = index
        
        let track = tracks[index]
        audioManager.loadTrack(track)
        audioManager.play()
    }
    
    func togglePlayPause() {
        audioManager.togglePlayPause()
    }
    
    func nextTrack() {
        guard hasNextTrack else { return }
        
        switch repeatMode {
        case .one:
            audioManager.seek(to: 0)
            audioManager.play()
        case .all:
            if shuffleEnabled {
                playRandomTrack()
            } else {
                let nextIndex = (currentTrackIndex + 1) % currentPlaylist.count
                playTrackAtIndex(nextIndex)
            }
        case .none:
            if shuffleEnabled {
                playRandomTrack()
            } else if currentTrackIndex < currentPlaylist.count - 1 {
                playTrackAtIndex(currentTrackIndex + 1)
            }
        }
    }
    
    func previousTrack() {
        guard hasPreviousTrack else { return }
        
        if audioManager.currentTime > 3.0 {
            audioManager.seek(to: 0)
            return
        }
        
        switch repeatMode {
        case .one:
            audioManager.seek(to: 0)
            audioManager.play()
        case .all:
            if shuffleEnabled {
                playRandomTrack()
            } else {
                let previousIndex = currentTrackIndex == 0 ? currentPlaylist.count - 1 : currentTrackIndex - 1
                playTrackAtIndex(previousIndex)
            }
        case .none:
            if shuffleEnabled {
                playRandomTrack()
            } else if currentTrackIndex > 0 {
                playTrackAtIndex(currentTrackIndex - 1)
            }
        }
    }
    
    func seek(to time: TimeInterval) {
        audioManager.seek(to: time)
    }
    
    func seekForward() {
        audioManager.seekForward()
    }
    
    func seekBackward() {
        audioManager.seekBackward()
    }
    
    func toggleShuffle() {
        audioManager.toggleShuffle()
    }
    
    func setRepeatMode(_ mode: RepeatMode) {
        audioManager.setRepeatMode(mode)
    }
    
    func showLibrary() {
        showingLibrary = true
    }
    
    func hideLibrary() {
        showingLibrary = false
    }
    
    private func playTrackAtIndex(_ index: Int) {
        guard index >= 0 && index < currentPlaylist.count else { return }
        
        currentTrackIndex = index
        let track = currentPlaylist[index]
        audioManager.loadTrack(track)
        audioManager.play()
    }
    
    private func playRandomTrack() {
        guard !currentPlaylist.isEmpty else { return }
        
        var availableIndices = Array(0..<currentPlaylist.count)
        if currentPlaylist.count > 1 {
            availableIndices.removeAll { $0 == currentTrackIndex }
        }
        
        if let randomIndex = availableIndices.randomElement() {
            playTrackAtIndex(randomIndex)
        }
    }
    
    private func updateCurrentTrackIndex(for track: MusicTrack) {
        if let index = currentPlaylist.firstIndex(of: track) {
            currentTrackIndex = index
        }
    }
    
    private func handleTrackFinished() {
        switch repeatMode {
        case .one:
            audioManager.seek(to: 0)
            audioManager.play()
        case .all:
            nextTrack()
        case .none:
            if hasNextTrack {
                nextTrack()
            }
        }
    }
    
    func addToPlaylist(_ track: MusicTrack) {
        if !currentPlaylist.contains(track) {
            currentPlaylist.append(track)
        }
    }
    
    func removeFromPlaylist(_ track: MusicTrack) {
        if let index = currentPlaylist.firstIndex(of: track) {
            currentPlaylist.remove(at: index)
            
            if index < currentTrackIndex {
                currentTrackIndex -= 1
            } else if index == currentTrackIndex {
                if currentTrackIndex >= currentPlaylist.count {
                    currentTrackIndex = max(0, currentPlaylist.count - 1)
                }
                
                if !currentPlaylist.isEmpty && audioManager.playerState.isPlaying {
                    playTrackAtIndex(currentTrackIndex)
                }
            }
        }
    }
    
    func clearPlaylist() {
        audioManager.stop()
        currentPlaylist.removeAll()
        currentTrackIndex = 0
    }
}