//
//  AudioPlayerManager.swift
//  AsaVoiceMemo
//  
//  Created on 2025/07/28
//

import Foundation
import AVFoundation
import Combine

enum PlayerState {
    case stopped
    case playing
    case paused
    case loading
    
    var isPlaying: Bool {
        return self == .playing
    }
}

@Observable
class AudioPlayerManager: NSObject {
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    
    var currentVoiceMemo: VoiceMemo?
    var playerState: PlayerState = .stopped
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var volume: Float = 1.0 {
        didSet {
            audioPlayer?.volume = volume
        }
    }
    
    var isPlaying: Bool {
        return playerState.isPlaying
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    // フォーマットされた現在時間
    var formattedCurrentTime: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // フォーマットされた総時間
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
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
    
    // 音声メモを読み込み
    func loadVoiceMemo(_ voiceMemo: VoiceMemo) {
        currentVoiceMemo = voiceMemo
        playerState = .loading
        
        // ファイルが存在するかチェック
        guard voiceMemo.fileExists else {
            print("音声ファイルが見つかりません: \(voiceMemo.fileURL)")
            playerState = .stopped
            return
        }
        
        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: voiceMemo.fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = volume
            
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            playerState = .stopped
        } catch {
            print("音声ファイルの読み込みに失敗しました: \(error)")
            playerState = .stopped
        }
    }
    
    // 再生開始
    func play() {
        guard let player = audioPlayer else { return }
        
        if player.play() {
            playerState = .playing
            startProgressTimer()
        }
    }
    
    // 一時停止
    func pause() {
        audioPlayer?.pause()
        playerState = .paused
        stopProgressTimer()
    }
    
    // 停止
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        currentTime = 0
        playerState = .stopped
        stopProgressTimer()
    }
    
    // 再生/一時停止の切り替え
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
    
    // 指定時間にシーク
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        
        let clampedTime = max(0, min(time, duration))
        player.currentTime = clampedTime
        currentTime = clampedTime
    }
    
    // 前に15秒戻る
    func seekBackward(_ seconds: TimeInterval = 15) {
        let newTime = max(0, currentTime - seconds)
        seek(to: newTime)
    }
    
    // 次に15秒進む
    func seekForward(_ seconds: TimeInterval = 15) {
        let newTime = min(duration, currentTime + seconds)
        seek(to: newTime)
    }
    
    // 再生速度設定（オプション機能）
    func setPlaybackRate(_ rate: Float) {
        audioPlayer?.rate = rate
    }
    
    // 進捗タイマーの開始
    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    // 進捗タイマーの停止
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    // 進捗の更新
    private func updateProgress() {
        guard let player = audioPlayer else { return }
        currentTime = player.currentTime
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playerState = .stopped
        currentTime = 0
        stopProgressTimer()
        
        if flag {
            // 再生完了時の処理
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("オーディオデコードエラー: \(error?.localizedDescription ?? "不明なエラー")")
        playerState = .stopped
        stopProgressTimer()
    }
}