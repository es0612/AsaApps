import Foundation
import Combine
import AVFoundation

@Observable
final class PodcastPlayerViewModel {
    // MARK: - Published Properties
    var currentEpisode: PodcastEpisode?
    var currentPlaylist: [PodcastEpisode] = []
    var currentEpisodeIndex: Int = 0
    var subscribedPodcasts: [Podcast] = []
    var searchText: String = ""
    var showingLibrary: Bool = false
    var showingEpisodeDetail: Bool = false
    var selectedPodcast: Podcast?
    
    // Player Settings
    var playbackRate: Float = 1.0 {
        didSet {
            audioManager.setPlaybackRate(playbackRate)
            saveSettings()
        }
    }
    
    var autoPlayNext: Bool = true {
        didSet { saveSettings() }
    }
    
    var skipForwardDuration: TimeInterval = 30 {
        didSet { saveSettings() }
    }
    
    var skipBackwardDuration: TimeInterval = 15 {
        didSet { saveSettings() }
    }
    
    var sleepTimerEnabled: Bool = false
    var sleepTimerDuration: TimeInterval = 0
    private var sleepTimerStartTime: Date?
    
    // MARK: - Private Properties
    private let audioManager: PodcastAudioManager
    private let libraryManager: PodcastLibraryManager
    private var cancellables = Set<AnyCancellable>()
    private var playbackPositionTimer: Timer?
    
    // MARK: - Computed Properties
    
    var playerState: PodcastPlayerState {
        audioManager.playerState
    }
    
    var currentTime: TimeInterval {
        audioManager.currentTime
    }
    
    var duration: TimeInterval {
        audioManager.duration
    }
    
    var progress: Double {
        audioManager.progress
    }
    
    var volume: Float {
        get { audioManager.volume }
        set { audioManager.volume = newValue }
    }
    
    var isLoading: Bool {
        libraryManager.isLoading
    }
    
    var hasNextEpisode: Bool {
        return currentEpisodeIndex < currentPlaylist.count - 1
    }
    
    var hasPreviousEpisode: Bool {
        return currentEpisodeIndex > 0
    }
    
    var filteredPodcasts: [Podcast] {
        if searchText.isEmpty {
            return subscribedPodcasts
        } else {
            return subscribedPodcasts.filter { podcast in
                podcast.displayName.localizedCaseInsensitiveContains(searchText) ||
                podcast.displayAuthor.localizedCaseInsensitiveContains(searchText) ||
                podcast.episodes.contains { episode in
                    episode.displayTitle.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    }
    
    var availablePlaybackRates: [Float] {
        return [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
    }
    
    var formattedPlaybackRate: String {
        if playbackRate == 1.0 {
            return "1x"
        } else {
            return String(format: "%.2gx", playbackRate)
        }
    }
    
    var sleepTimerRemainingTime: TimeInterval {
        guard sleepTimerEnabled, let startTime = sleepTimerStartTime else { return 0 }
        let elapsed = Date().timeIntervalSince(startTime)
        return max(0, sleepTimerDuration - elapsed)
    }
    
    var formattedSleepTimerRemainingTime: String {
        let remaining = sleepTimerRemainingTime
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Initialization
    
    init(
        audioManager: PodcastAudioManager = PodcastAudioManager(),
        libraryManager: PodcastLibraryManager = PodcastLibraryManager()
    ) {
        self.audioManager = audioManager
        self.libraryManager = libraryManager
        
        setupBindings()
        loadSettings()
        loadPodcastLibrary()
        startPlaybackPositionTimer()
    }
    
    deinit {
        stopPlaybackPositionTimer()
    }
    
    // MARK: - Setup Methods
    
    private func setupBindings() {
        // Sleep timer
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkSleepTimer()
                // 定期的にaudioManagerの状態をチェック
                self?.syncWithAudioManager()
            }
            .store(in: &cancellables)
    }
    
    private func syncWithAudioManager() {
        // AudioManagerの状態と同期
        if currentEpisode != audioManager.currentEpisode {
            currentEpisode = audioManager.currentEpisode
            if let episode = currentEpisode {
                updateCurrentEpisodeIndex(for: episode)
            }
        }
        
        if audioManager.playerState == .finished {
            handleEpisodeFinished()
        }
    }
    
    private func startPlaybackPositionTimer() {
        playbackPositionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.savePlaybackPosition()
        }
    }
    
    private func stopPlaybackPositionTimer() {
        playbackPositionTimer?.invalidate()
        playbackPositionTimer = nil
    }
    
    // MARK: - Library Management
    
    func loadPodcastLibrary() {
        libraryManager.loadPodcasts()
        subscribedPodcasts = libraryManager.subscribedPodcasts
    }
    
    func subscribeToPodcast(_ podcast: Podcast) {
        var updatedPodcast = podcast
        updatedPodcast.subscribe()
        
        if let index = subscribedPodcasts.firstIndex(where: { $0.id == podcast.id }) {
            subscribedPodcasts[index] = updatedPodcast
        } else {
            subscribedPodcasts.append(updatedPodcast)
        }
        
        libraryManager.savePodcast(updatedPodcast)
    }
    
    func unsubscribeFromPodcast(_ podcast: Podcast) {
        var updatedPodcast = podcast
        updatedPodcast.unsubscribe()
        
        if let index = subscribedPodcasts.firstIndex(where: { $0.id == podcast.id }) {
            subscribedPodcasts[index] = updatedPodcast
        }
        
        libraryManager.savePodcast(updatedPodcast)
    }
    
    // MARK: - Playback Control
    
    func playEpisode(_ episode: PodcastEpisode) {
        audioManager.loadEpisode(episode)
        audioManager.setPlaybackRate(playbackRate)
        
        // Restore saved playback position
        if episode.playbackPosition > 0 {
            audioManager.seek(to: episode.playbackPosition)
        }
        
        audioManager.play()
        updateCurrentEpisodeInPlaylist(episode)
    }
    
    func playPlaylist(_ episodes: [PodcastEpisode], startingAt index: Int = 0) {
        guard !episodes.isEmpty && index >= 0 && index < episodes.count else { return }
        
        currentPlaylist = episodes
        currentEpisodeIndex = index
        
        let episode = episodes[index]
        playEpisode(episode)
    }
    
    func togglePlayPause() {
        audioManager.togglePlayPause()
    }
    
    func nextEpisode() {
        guard hasNextEpisode else { return }
        
        markCurrentEpisodeProgress()
        let nextIndex = currentEpisodeIndex + 1
        playEpisodeAtIndex(nextIndex)
    }
    
    func previousEpisode() {
        // If we're more than 10 seconds in, restart current episode
        if audioManager.currentTime > 10.0 {
            audioManager.seek(to: 0)
            return
        }
        
        guard hasPreviousEpisode else { return }
        
        let previousIndex = currentEpisodeIndex - 1
        playEpisodeAtIndex(previousIndex)
    }
    
    func seek(to time: TimeInterval) {
        audioManager.seek(to: time)
    }
    
    func skipForward() {
        let newTime = audioManager.currentTime + skipForwardDuration
        seek(to: min(newTime, audioManager.duration))
    }
    
    func skipBackward() {
        let newTime = audioManager.currentTime - skipBackwardDuration
        seek(to: max(newTime, 0))
    }
    
    func setPlaybackRate(_ rate: Float) {
        playbackRate = max(0.5, min(2.0, rate))
    }
    
    func nextPlaybackRate() {
        let currentIndex = availablePlaybackRates.firstIndex(of: playbackRate) ?? 2
        let nextIndex = (currentIndex + 1) % availablePlaybackRates.count
        setPlaybackRate(availablePlaybackRates[nextIndex])
    }
    
    // MARK: - Sleep Timer
    
    func setSleepTimer(duration: TimeInterval) {
        sleepTimerEnabled = true
        sleepTimerDuration = duration
        sleepTimerStartTime = Date()
    }
    
    func cancelSleepTimer() {
        sleepTimerEnabled = false
        sleepTimerDuration = 0
        sleepTimerStartTime = nil
    }
    
    private func checkSleepTimer() {
        guard sleepTimerEnabled else { return }
        
        if sleepTimerRemainingTime <= 0 {
            audioManager.pause()
            cancelSleepTimer()
        }
    }
    
    // MARK: - Episode Management
    
    func toggleEpisodeBookmark(_ episode: PodcastEpisode) {
        var updatedEpisode = episode
        updatedEpisode.toggleBookmark()
        updateEpisodeInPodcasts(updatedEpisode)
        
        if currentEpisode?.id == episode.id {
            currentEpisode = updatedEpisode
        }
    }
    
    func markEpisodeAsPlayed(_ episode: PodcastEpisode) {
        var updatedEpisode = episode
        updatedEpisode.markAsPlayed()
        updateEpisodeInPodcasts(updatedEpisode)
    }
    
    func markEpisodeAsUnplayed(_ episode: PodcastEpisode) {
        var updatedEpisode = episode
        updatedEpisode.markAsUnplayed()
        updateEpisodeInPodcasts(updatedEpisode)
    }
    
    // MARK: - UI Control
    
    func showLibrary() {
        showingLibrary = true
    }
    
    func hideLibrary() {
        showingLibrary = false
    }
    
    func showEpisodeDetail(for episode: PodcastEpisode) {
        currentEpisode = episode
        showingEpisodeDetail = true
    }
    
    func hideEpisodeDetail() {
        showingEpisodeDetail = false
    }
    
    func selectPodcast(_ podcast: Podcast) {
        selectedPodcast = podcast
    }
    
    // MARK: - Private Helper Methods
    
    private func playEpisodeAtIndex(_ index: Int) {
        guard index >= 0 && index < currentPlaylist.count else { return }
        
        currentEpisodeIndex = index
        let episode = currentPlaylist[index]
        playEpisode(episode)
    }
    
    private func updateCurrentEpisodeIndex(for episode: PodcastEpisode) {
        if let index = currentPlaylist.firstIndex(where: { $0.id == episode.id }) {
            currentEpisodeIndex = index
        }
    }
    
    private func updateCurrentEpisodeInPlaylist(_ episode: PodcastEpisode) {
        if !currentPlaylist.contains(where: { $0.id == episode.id }) {
            currentPlaylist = [episode]
            currentEpisodeIndex = 0
        } else {
            updateCurrentEpisodeIndex(for: episode)
        }
    }
    
    private func handleEpisodeFinished() {
        markCurrentEpisodeProgress()
        
        if autoPlayNext && hasNextEpisode {
            nextEpisode()
        } else {
            // Mark episode as played when finished
            if let currentEpisode = currentEpisode {
                markEpisodeAsPlayed(currentEpisode)
            }
        }
    }
    
    private func markCurrentEpisodeProgress() {
        guard var episode = currentEpisode else { return }
        
        episode.updatePlaybackPosition(audioManager.currentTime)
        updateEpisodeInPodcasts(episode)
        currentEpisode = episode
    }
    
    private func savePlaybackPosition() {
        guard playerState == .playing,
              var episode = currentEpisode,
              audioManager.currentTime > 0 else { return }
        
        episode.updatePlaybackPosition(audioManager.currentTime)
        updateEpisodeInPodcasts(episode)
        currentEpisode = episode
    }
    
    private func updateEpisodeInPodcasts(_ updatedEpisode: PodcastEpisode) {
        for (podcastIndex, var podcast) in subscribedPodcasts.enumerated() {
            if let episodeIndex = podcast.episodes.firstIndex(where: { $0.id == updatedEpisode.id }) {
                podcast.episodes[episodeIndex] = updatedEpisode
                subscribedPodcasts[podcastIndex] = podcast
                libraryManager.savePodcast(podcast)
                break
            }
        }
        
        // Update current playlist if needed
        if let playlistIndex = currentPlaylist.firstIndex(where: { $0.id == updatedEpisode.id }) {
            currentPlaylist[playlistIndex] = updatedEpisode
        }
    }
    
    // MARK: - Settings Persistence
    
    private func loadSettings() {
        let userDefaults = UserDefaults.standard
        playbackRate = Float(userDefaults.object(forKey: "PodcastPlayerPlaybackRate") as? Double ?? 1.0)
        autoPlayNext = userDefaults.object(forKey: "PodcastPlayerAutoPlayNext") as? Bool ?? true
        skipForwardDuration = userDefaults.object(forKey: "PodcastPlayerSkipForward") as? TimeInterval ?? 30.0
        skipBackwardDuration = userDefaults.object(forKey: "PodcastPlayerSkipBackward") as? TimeInterval ?? 15.0
    }
    
    private func saveSettings() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(playbackRate, forKey: "PodcastPlayerPlaybackRate")
        userDefaults.set(autoPlayNext, forKey: "PodcastPlayerAutoPlayNext")
        userDefaults.set(skipForwardDuration, forKey: "PodcastPlayerSkipForward")
        userDefaults.set(skipBackwardDuration, forKey: "PodcastPlayerSkipBackward")
    }
}

// MARK: - Player State Enum

enum PodcastPlayerState: String, CaseIterable {
    case stopped = "stopped"
    case playing = "playing"
    case paused = "paused"
    case loading = "loading"
    case finished = "finished"
    case error = "error"
    
    var isPlaying: Bool { self == .playing }
    var isPaused: Bool { self == .paused }
    var isStopped: Bool { self == .stopped }
    var isLoading: Bool { self == .loading }
    var isFinished: Bool { self == .finished }
    var hasError: Bool { self == .error }
}