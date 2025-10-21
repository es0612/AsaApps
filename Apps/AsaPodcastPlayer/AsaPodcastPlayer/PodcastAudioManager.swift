//
//  PodcastAudioManager.swift
//  AsaPodcastPlayer
//
//  Created by AsaPapa on 2025-10-21.
//

import AVFoundation
import Combine

/// Podcast音声再生を管理するクラス
@Observable
final class PodcastAudioManager: NSObject {
    // MARK: - Properties

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    var isPlaying: Bool = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var playbackRate: Float = 1.0

    // MARK: - Initialization

    override init() {
        super.init()
        setupAudioSession()
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("オーディオセッションのセットアップに失敗しました: \(error.localizedDescription)")
        }
    }

    // MARK: - Audio Loading

    /// 音声ファイルを読み込む
    /// - Parameter fileName: 音声ファイル名（拡張子含む）
    func loadAudio(fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".m4a", with: ""), withExtension: "m4a") else {
            print("音声ファイルが見つかりません: \(fileName)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.enableRate = true
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
        } catch {
            print("音声ファイルの読み込みに失敗しました: \(error.localizedDescription)")
        }
    }

    // MARK: - Playback Controls

    /// 再生
    func play() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }

    /// 一時停止
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }

    /// 再生/一時停止のトグル
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    /// 指定時間へシーク
    /// - Parameter time: シーク先の時間（秒）
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }

    /// 指定秒数スキップ
    /// - Parameter seconds: スキップする秒数（負の値で戻る）
    func skip(seconds: TimeInterval) {
        let newTime = max(0, min(duration, currentTime + seconds))
        seek(to: newTime)
    }

    /// 再生速度を変更
    /// - Parameter rate: 再生速度（0.5〜2.0）
    func setPlaybackRate(_ rate: Float) {
        playbackRate = max(0.5, min(2.0, rate))
        audioPlayer?.rate = playbackRate
    }

    // MARK: - Timer

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentTime = self.audioPlayer?.currentTime ?? 0
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Cleanup

    deinit {
        stopTimer()
        audioPlayer?.stop()
    }
}

// MARK: - AVAudioPlayerDelegate

extension PodcastAudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopTimer()
        currentTime = 0
        seek(to: 0)
    }
}
