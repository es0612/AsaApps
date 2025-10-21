//
//  PodcastPlayerViewModel.swift
//  AsaPodcastPlayer
//
//  Created by AsaPapa on 2025-10-21.
//

import Foundation

/// PodcastプレイヤーのViewModel
@Observable
final class PodcastPlayerViewModel {
    // MARK: - Properties

    private let audioManager = PodcastAudioManager()

    var currentEpisode: PodcastEpisode?
    var episodes: [PodcastEpisode] = PodcastEpisode.sampleEpisodes

    var isPlaying: Bool {
        audioManager.isPlaying
    }

    var currentTime: TimeInterval {
        audioManager.currentTime
    }

    var duration: TimeInterval {
        audioManager.duration
    }

    var playbackRate: Float {
        audioManager.playbackRate
    }

    var currentTimeFormatted: String {
        formatTime(currentTime)
    }

    var durationFormatted: String {
        formatTime(duration)
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    // MARK: - Available Playback Rates

    let availablePlaybackRates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    // MARK: - Initialization

    init() {
        // 最初のエピソードを読み込む
        if let firstEpisode = episodes.first {
            loadEpisode(firstEpisode)
        }
    }

    // MARK: - Episode Management

    /// エピソードを読み込む
    /// - Parameter episode: 読み込むエピソード
    func loadEpisode(_ episode: PodcastEpisode) {
        currentEpisode = episode
        audioManager.loadAudio(fileName: episode.audioFileName)
    }

    /// エピソードを選択して読み込む
    /// - Parameter episode: 選択するエピソード
    func selectEpisode(_ episode: PodcastEpisode) {
        loadEpisode(episode)
    }

    // MARK: - Playback Controls

    /// 再生/一時停止のトグル
    func togglePlayPause() {
        audioManager.togglePlayPause()
    }

    /// 再生
    func play() {
        audioManager.play()
    }

    /// 一時停止
    func pause() {
        audioManager.pause()
    }

    /// シーク
    /// - Parameter time: シーク先の時間（秒）
    func seek(to time: TimeInterval) {
        audioManager.seek(to: time)
    }

    /// 進む（30秒）
    func skipForward() {
        audioManager.skip(seconds: 30)
    }

    /// 戻る（30秒）
    func skipBackward() {
        audioManager.skip(seconds: -30)
    }

    /// 再生速度を変更
    /// - Parameter rate: 再生速度
    func changePlaybackRate(_ rate: Float) {
        audioManager.setPlaybackRate(rate)
    }

    /// 次の再生速度に変更
    func nextPlaybackRate() {
        guard let currentIndex = availablePlaybackRates.firstIndex(of: playbackRate) else { return }
        let nextIndex = (currentIndex + 1) % availablePlaybackRates.count
        changePlaybackRate(availablePlaybackRates[nextIndex])
    }

    // MARK: - Formatting

    /// 時間をフォーマット（MM:SS）
    /// - Parameter time: 時間（秒）
    /// - Returns: フォーマットされた文字列
    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
