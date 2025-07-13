import Foundation
import AVFoundation
import Combine

class AudioManager: NSObject, ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    
    @Published var currentTrack: MusicTrack?
    @Published var playerState: MusicPlayerState = .stopped
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 1.0 {
        didSet {
            audioPlayer?.volume = volume
        }
    }
    
    @Published var shuffleEnabled: Bool = false
    @Published var repeatMode: RepeatMode = .none
    
    var isPlaying: Bool {
        return playerState.isPlaying
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    deinit {
        stopProgressTimer()
        audioPlayer?.stop()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("オーディオセッションの設定に失敗しました: \(error)")
        }
    }
    
    func loadTrack(_ track: MusicTrack) {
        currentTrack = track
        playerState = .loading
        
        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: track.filePath)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = volume
            
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            playerState = .stopped
        } catch {
            print("音楽ファイルの読み込みに失敗しました: \(error)")
            playerState = .stopped
        }
    }
    
    func play() {
        guard let player = audioPlayer else { return }
        
        if player.play() {
            playerState = .playing
            startProgressTimer()
        }
    }
    
    func pause() {
        audioPlayer?.pause()
        playerState = .paused
        stopProgressTimer()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        currentTime = 0
        playerState = .stopped
        stopProgressTimer()
    }
    
    func togglePlayPause() {
        switch playerState {
        case .playing:
            pause()
        case .paused, .stopped:
            play()
        case .loading:
            break
        }
    }
    
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        
        let clampedTime = max(0, min(time, duration))
        player.currentTime = clampedTime
        currentTime = clampedTime
    }
    
    func seekForward(_ seconds: TimeInterval = 15) {
        let newTime = currentTime + seconds
        seek(to: newTime)
    }
    
    func seekBackward(_ seconds: TimeInterval = 15) {
        let newTime = currentTime - seconds
        seek(to: newTime)
    }
    
    func setRepeatMode(_ mode: RepeatMode) {
        repeatMode = mode
    }
    
    func toggleShuffle() {
        shuffleEnabled.toggle()
    }
    
    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
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
    }
}

extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playerState = .stopped
        currentTime = 0
        stopProgressTimer()
        
        if flag {
            
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("オーディオデコードエラー: \(error?.localizedDescription ?? "不明なエラー")")
        playerState = .stopped
        stopProgressTimer()
    }
}