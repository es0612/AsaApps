import XCTest
@testable import AsaPodcastPlayer

final class AsaPodcastPlayerTests: XCTestCase {
    
    func testPodcastEpisodeInitialization() {
        // Given
        let title = "テストエピソード"
        let duration: TimeInterval = 1800 // 30分
        let filePath = URL(fileURLWithPath: "/tmp/test.mp3")
        let podcastName = "テストポッドキャスト"
        
        // When
        let episode = PodcastEpisode(
            title: title,
            description: "テスト用のエピソード説明",
            duration: duration,
            filePath: filePath,
            podcastName: podcastName
        )
        
        // Then
        XCTAssertEqual(episode.displayTitle, title)
        XCTAssertEqual(episode.duration, duration)
        XCTAssertEqual(episode.podcastName, podcastName)
        XCTAssertEqual(episode.playbackPosition, 0)
        XCTAssertFalse(episode.isPlayed)
        XCTAssertFalse(episode.isBookmarked)
    }
    
    func testPodcastEpisodeDurationFormatting() {
        // Given
        let episode30Min = PodcastEpisode(
            title: "30分エピソード",
            duration: 1800, // 30分
            filePath: URL(fileURLWithPath: "/tmp/test1.mp3"),
            podcastName: "テストポッドキャスト"
        )
        
        let episode1Hour30Min = PodcastEpisode(
            title: "1時間30分エピソード",
            duration: 5400, // 1時間30分
            filePath: URL(fileURLWithPath: "/tmp/test2.mp3"),
            podcastName: "テストポッドキャスト"
        )
        
        // Then
        XCTAssertEqual(episode30Min.formattedDuration, "30:00")
        XCTAssertEqual(episode1Hour30Min.formattedDuration, "1:30:00")
    }
    
    func testPodcastEpisodeProgressUpdate() {
        // Given
        var episode = PodcastEpisode(
            title: "進捗テスト",
            duration: 3600, // 1時間
            filePath: URL(fileURLWithPath: "/tmp/progress_test.mp3"),
            podcastName: "テストポッドキャスト"
        )
        
        // When
        episode.updatePlaybackPosition(1800) // 30分再生
        
        // Then
        XCTAssertEqual(episode.playbackPosition, 1800)
        XCTAssertEqual(episode.playbackProgress, 0.5, accuracy: 0.01)
        XCTAssertFalse(episode.isPlayed) // まだ90%未満
        
        // When - 90%以上再生
        episode.updatePlaybackPosition(3300) // 55分再生（91.67%）
        
        // Then
        XCTAssertTrue(episode.isPlayed) // 90%以上で自動的にマーク
    }
    
    func testPodcastStatistics() {
        // Given
        let episode1 = PodcastEpisode(
            title: "エピソード1",
            duration: 1800,
            filePath: URL(fileURLWithPath: "/tmp/ep1.mp3"),
            podcastName: "テストポッドキャスト",
            playbackPosition: 1800,
            isPlayed: true
        )
        
        let episode2 = PodcastEpisode(
            title: "エピソード2",
            duration: 3600,
            filePath: URL(fileURLWithPath: "/tmp/ep2.mp3"),
            podcastName: "テストポッドキャスト",
            playbackPosition: 1800,
            isPlayed: false
        )
        
        let podcast = Podcast(
            name: "テストポッドキャスト",
            description: "テスト用ポッドキャスト",
            author: "テスト作者",
            episodes: [episode1, episode2]
        )
        
        // Then
        XCTAssertEqual(podcast.totalEpisodes, 2)
        XCTAssertEqual(podcast.playedEpisodes, 1)
        XCTAssertEqual(podcast.unplayedEpisodes, 1)
        XCTAssertEqual(podcast.inProgressEpisodes, 1)
        XCTAssertEqual(podcast.totalDuration, 5400) // 1800 + 3600
    }
    
    func testPodcastPlayerViewModelInitialization() {
        // Given & When
        let viewModel = PodcastPlayerViewModel()
        
        // Then
        XCTAssertNil(viewModel.currentEpisode)
        XCTAssertTrue(viewModel.currentPlaylist.isEmpty)
        XCTAssertEqual(viewModel.playbackRate, 1.0)
        XCTAssertTrue(viewModel.autoPlayNext)
        XCTAssertFalse(viewModel.sleepTimerEnabled)
    }
    
    func testPlaybackRateChange() {
        // Given
        let viewModel = PodcastPlayerViewModel()
        
        // When
        viewModel.setPlaybackRate(1.5)
        
        // Then
        XCTAssertEqual(viewModel.playbackRate, 1.5)
        XCTAssertEqual(viewModel.formattedPlaybackRate, "1.5x")
        
        // When - 範囲外の値
        viewModel.setPlaybackRate(3.0) // 最大2.0に制限される
        
        // Then
        XCTAssertEqual(viewModel.playbackRate, 2.0)
        
        // When - 範囲外の値（下限）
        viewModel.setPlaybackRate(0.1) // 最小0.5に制限される
        
        // Then
        XCTAssertEqual(viewModel.playbackRate, 0.5)
    }
    
    func testPodcastLibraryManagerSearch() {
        // Given
        let libraryManager = PodcastLibraryManager()
        let podcast1 = Podcast(
            name: "朝活ラジオ",
            author: "朝活パパ",
            episodes: []
        )
        let podcast2 = Podcast(
            name: "テックトーク",
            author: "エンジニア",
            episodes: []
        )
        
        libraryManager.subscribedPodcasts = [podcast1, podcast2]
        
        // When & Then
        let searchResults1 = libraryManager.searchPodcasts(query: "朝活")
        XCTAssertEqual(searchResults1.count, 1)
        XCTAssertEqual(searchResults1.first?.name, "朝活ラジオ")
        
        let searchResults2 = libraryManager.searchPodcasts(query: "エンジニア")
        XCTAssertEqual(searchResults2.count, 1)
        XCTAssertEqual(searchResults2.first?.name, "テックトーク")
        
        let searchResults3 = libraryManager.searchPodcasts(query: "")
        XCTAssertEqual(searchResults3.count, 2) // 空文字列は全て返す
    }
}