import Foundation
import AVFoundation
import Combine

@Observable
final class PodcastAudioManager: NSObject {
    // MARK: - Published Properties
    var currentEpisode: PodcastEpisode?
    var playerState: PodcastPlayerState = .stopped
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var volume: Float = 1.0 {
        didSet {
            audioPlayer?.volume = volume
            saveVolumeToDefaults()
        }
    }
    var playbackRate: Float = 1.0 {
        didSet {
            updatePlaybackRate()
            savePlaybackRateToDefaults()
        }
    }
    
    // MARK: - Private Properties
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Computed Properties
    
    var isPlaying: Bool {
        return playerState.isPlaying
    }
    
    var isPaused: Bool {
        return playerState.isPaused
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    var formattedCurrentTime: String {
        return formatTime(currentTime)
    }
    
    var formattedDuration: String {
        return formatTime(duration)
    }
    
    var formattedRemainingTime: String {
        let remaining = max(0, duration - currentTime)
        return formatTime(remaining)
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupAudioSession()
        loadSettingsFromDefaults()
    }
    
    deinit {
        stopProgressTimer()
        audioPlayer?.stop()
        deactivateAudioSession()
    }
    
    // MARK: - Audio Session Management
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true)
            
            // Listen for audio session interruptions
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioSessionInterruption),
                name: AVAudioSession.interruptionNotification,
                object: nil
            )
            
            // Listen for route changes (headphones unplugged, etc.)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioSessionRouteChange),
                name: AVAudioSession.routeChangeNotification,
                object: nil
            )
            
        } catch {
            print("オーディオセッションの設定に失敗しました: \(error)")
        }
    }
    
    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("オーディオセッションの非アクティブ化に失敗しました: \(error)")
        }
    }
    
    // MARK: - Episode Loading and Playback
    
    func loadEpisode(_ episode: PodcastEpisode) {
        currentEpisode = episode
        playerState = .loading
        
        do {
            // Stop current playback
            audioPlayer?.stop()
            
            // Create new audio player
            audioPlayer = try AVAudioPlayer(contentsOf: episode.filePath)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = volume
            audioPlayer?.enableRate = true // Enable playback rate control
            audioPlayer?.rate = playbackRate
            
            // Update properties
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            playerState = .stopped
            
            print("エピソード読み込み完了: \(episode.displayTitle)")
            
        } catch {
            print("ポッドキャストエピソードの読み込みに失敗しました: \(error)")
            playerState = .error
        }
    }
    
    func play() {
        guard let player = audioPlayer else {
            print("オーディオプレイヤーが初期化されていません")
            return
        }
        
        do {
            // Reactivate audio session if needed
            try AVAudioSession.sharedInstance().setActive(true)
            
            if player.play() {
                playerState = .playing
                startProgressTimer()
                print("再生開始: \(currentEpisode?.displayTitle ?? "不明")")
            } else {
                print("再生の開始に失敗しました")
                playerState = .error
            }
        } catch {
            print("オーディオセッションのアクティブ化に失敗しました: \(error)")
            playerState = .error
        }
    }
    
    func pause() {
        audioPlayer?.pause()
        playerState = .paused
        stopProgressTimer()
        print("再生一時停止")
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        currentTime = 0
        playerState = .stopped
        stopProgressTimer()
        print("再生停止")
    }
    
    func togglePlayPause() {
        switch playerState {
        case .playing:
            pause()
        case .paused, .stopped:
            play()
        case .loading, .error:
            break
        case .finished:
            // Restart from beginning
            seek(to: 0)
            play()
        }
    }
    
    // MARK: - Seeking and Navigation
    
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer, duration > 0 else { return }
        
        let clampedTime = max(0, min(time, duration))
        player.currentTime = clampedTime
        currentTime = clampedTime
        
        print("シーク: \(formatTime(clampedTime))")
    }
    
    func skipForward(_ seconds: TimeInterval = 30) {
        let newTime = currentTime + seconds
        seek(to: newTime)
        print("早送り: +\(Int(seconds))秒")
    }
    
    func skipBackward(_ seconds: TimeInterval = 15) {
        let newTime = currentTime - seconds
        seek(to: newTime)
        print("巻き戻し: -\(Int(seconds))秒")
    }
    
    func seekToPercentage(_ percentage: Double) {
        let newTime = duration * max(0, min(1, percentage))
        seek(to: newTime)
    }
    
    // MARK: - Playback Rate Control
    
    func setPlaybackRate(_ rate: Float) {
        let clampedRate = max(0.5, min(2.0, rate))
        playbackRate = clampedRate
    }
    
    func nextPlaybackRate() {
        let availableRates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
        let currentIndex = availableRates.firstIndex(of: playbackRate) ?? 2
        let nextIndex = (currentIndex + 1) % availableRates.count
        setPlaybackRate(availableRates[nextIndex])
    }
    
    private func updatePlaybackRate() {
        audioPlayer?.rate = playbackRate
        print("再生速度変更: \(playbackRate)x")
    }
    
    // MARK: - Progress Tracking
    
    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func updateProgress() {
        guard let player = audioPlayer else { return }
        currentTime = player.currentTime
        
        // Check if we're near the end
        if currentTime >= duration - 1.0 && playerState == .playing {
            handleEpisodeFinished()
        }
    }
    
    private func handleEpisodeFinished() {
        playerState = .finished
        stopProgressTimer()
        print("エピソード再生完了: \(currentEpisode?.displayTitle ?? "不明")")
    }
    
    // MARK: - Audio Session Event Handlers
    
    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let interruptionType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt else {
            return
        }
        
        switch AVAudioSession.InterruptionType(rawValue: interruptionType) {
        case .began:
            // Audio interruption began (e.g., phone call)
            if playerState == .playing {
                pause()
            }
            print("オーディオ割り込み開始")
            
        case .ended:
            // Audio interruption ended
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) && playerState == .paused {
                    play()
                }
            }
            print("オーディオ割り込み終了")
            
        default:
            break
        }
    }
    
    @objc private func handleAudioSessionRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt else {
            return
        }
        
        switch AVAudioSession.RouteChangeReason(rawValue: reasonValue) {
        case .oldDeviceUnavailable:
            // Headphones were unplugged
            if playerState == .playing {
                pause()
                print("ヘッドフォンが外されたため再生を一時停止")
            }
            
        default:
            break
        }
    }
    
    // MARK: - Settings Persistence
    
    private func loadSettingsFromDefaults() {
        volume = userDefaults.object(forKey: "PodcastAudioVolume") as? Float ?? 1.0
        playbackRate = userDefaults.object(forKey: "PodcastAudioPlaybackRate") as? Float ?? 1.0
    }
    
    private func saveVolumeToDefaults() {
        userDefaults.set(volume, forKey: "PodcastAudioVolume")
    }
    
    private func savePlaybackRateToDefaults() {
        userDefaults.set(playbackRate, forKey: "PodcastAudioPlaybackRate")
    }
    
    // MARK: - Utility Methods
    
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
    
    // MARK: - Public Utility Methods
    
    func getCurrentPlaybackInfo() -> (episode: PodcastEpisode?, currentTime: TimeInterval, duration: TimeInterval, progress: Double) {
        return (currentEpisode, currentTime, duration, progress)
    }
    
    func hasAudioData() -> Bool {
        return audioPlayer != nil && duration > 0
    }
    
    func isNearEnd(threshold: TimeInterval = 30) -> Bool {
        return duration > 0 && (duration - currentTime) <= threshold
    }
    
    func getBufferedDuration() -> TimeInterval {
        // AVAudioPlayer doesn't provide buffer information like AVPlayer
        // Return current time as a simple approximation
        return currentTime
    }
}

// MARK: - AVAudioPlayerDelegate

extension PodcastAudioManager: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("オーディオ再生完了: success = \(flag)")
        
        if flag {
            handleEpisodeFinished()
        } else {
            playerState = .error
            stopProgressTimer()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("オーディオデコードエラー: \(error?.localizedDescription ?? "不明なエラー")")
        playerState = .error
        stopProgressTimer()
    }
    
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        // Handle interruption begin (iOS 8 and earlier)
        if playerState == .playing {
            pause()
        }
        print("オーディオ割り込み開始（レガシー）")
    }
    
    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        // Handle interruption end (iOS 8 and earlier)
        if flags == AVAudioSession.InterruptionOptions.shouldResume.rawValue {
            play()
        }
        print("オーディオ割り込み終了（レガシー）")
    }
}