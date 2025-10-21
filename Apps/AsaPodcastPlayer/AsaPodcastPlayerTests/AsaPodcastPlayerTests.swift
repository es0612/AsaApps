//
//  AsaPodcastPlayerTests.swift
//  AsaPodcastPlayerTests
//
//  Created by AsaPapa on 2025-10-21.
//

import Testing
@testable import AsaPodcastPlayer

struct AsaPodcastPlayerTests {
    // MARK: - PodcastEpisode Tests

    @Test("PodcastEpisode初期化テスト")
    func testPodcastEpisodeInitialization() {
        let episode = PodcastEpisode(
            title: "テストエピソード",
            description: "テスト説明",
            audioFileName: "test.m4a"
        )

        #expect(episode.title == "テストエピソード")
        #expect(episode.description == "テスト説明")
        #expect(episode.audioFileName == "test.m4a")
    }

    @Test("サンプルエピソードが存在するかテスト")
    func testSampleEpisodesExist() {
        #expect(!PodcastEpisode.sampleEpisodes.isEmpty)
        #expect(PodcastEpisode.sampleEpisodes.count == 1)
    }

    // MARK: - PodcastPlayerViewModel Tests

    @Test("PodcastPlayerViewModel初期化テスト")
    func testViewModelInitialization() {
        let viewModel = PodcastPlayerViewModel()

        #expect(viewModel.episodes.count > 0)
        #expect(viewModel.currentEpisode != nil)
    }

    @Test("時間フォーマットテスト")
    func testTimeFormatting() {
        let viewModel = PodcastPlayerViewModel()

        // 初期状態では0:00であることを確認
        #expect(viewModel.currentTimeFormatted == "00:00")
    }

    @Test("再生速度変更テスト")
    func testPlaybackRateChange() {
        let viewModel = PodcastPlayerViewModel()
        let initialRate = viewModel.playbackRate

        viewModel.changePlaybackRate(1.5)

        #expect(viewModel.playbackRate == 1.5)
        #expect(viewModel.playbackRate != initialRate)
    }

    @Test("利用可能な再生速度テスト")
    func testAvailablePlaybackRates() {
        let viewModel = PodcastPlayerViewModel()

        #expect(viewModel.availablePlaybackRates.contains(0.5))
        #expect(viewModel.availablePlaybackRates.contains(1.0))
        #expect(viewModel.availablePlaybackRates.contains(1.5))
        #expect(viewModel.availablePlaybackRates.contains(2.0))
    }

    @Test("プログレス計算テスト")
    func testProgressCalculation() {
        let viewModel = PodcastPlayerViewModel()

        // 初期状態では0であることを確認
        #expect(viewModel.progress == 0)
    }
}
