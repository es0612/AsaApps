import Foundation
import AVFoundation
import UIKit

@Observable
final class PodcastLibraryManager {
    var subscribedPodcasts: [Podcast] = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let podcastsKey = "SavedPodcasts"
    
    init() {
        loadPodcasts()
    }
    
    // MARK: - Public Methods
    
    func loadPodcasts() {
        isLoading = true
        errorMessage = nil
        
        // Load from UserDefaults
        loadPodcastsFromStorage()
        
        // Load sample data if no podcasts exist
        if subscribedPodcasts.isEmpty {
            loadSamplePodcasts()
        }
        
        isLoading = false
    }
    
    func savePodcast(_ podcast: Podcast) {
        if let index = subscribedPodcasts.firstIndex(where: { $0.id == podcast.id }) {
            subscribedPodcasts[index] = podcast
        } else {
            subscribedPodcasts.append(podcast)
        }
        savePodcastsToStorage()
    }
    
    func deletePodcast(_ podcast: Podcast) {
        subscribedPodcasts.removeAll { $0.id == podcast.id }
        savePodcastsToStorage()
    }
    
    func searchPodcasts(query: String) -> [Podcast] {
        guard !query.isEmpty else { return subscribedPodcasts }
        
        let lowercaseQuery = query.lowercased()
        return subscribedPodcasts.filter { podcast in
            podcast.displayName.lowercased().contains(lowercaseQuery) ||
            podcast.displayAuthor.lowercased().contains(lowercaseQuery) ||
            podcast.displayDescription.lowercased().contains(lowercaseQuery)
        }
    }
    
    func getEpisodesFromPodcast(_ podcast: Podcast) -> [PodcastEpisode] {
        return podcast.episodes
    }
    
    func addEpisodeToPodcast(_ episode: PodcastEpisode, to podcast: Podcast) {
        guard let index = subscribedPodcasts.firstIndex(where: { $0.id == podcast.id }) else { return }
        
        var updatedPodcast = subscribedPodcasts[index]
        updatedPodcast.addEpisode(episode)
        subscribedPodcasts[index] = updatedPodcast
        savePodcastsToStorage()
    }
    
    func updateEpisodeInPodcast(_ episode: PodcastEpisode, in podcast: Podcast) {
        guard let podcastIndex = subscribedPodcasts.firstIndex(where: { $0.id == podcast.id }) else { return }
        
        var updatedPodcast = subscribedPodcasts[podcastIndex]
        updatedPodcast.updateEpisode(episode)
        subscribedPodcasts[podcastIndex] = updatedPodcast
        savePodcastsToStorage()
    }
    
    // MARK: - Private Methods
    
    private func loadPodcastsFromStorage() {
        if let data = userDefaults.data(forKey: podcastsKey),
           let decodedPodcasts = try? JSONDecoder().decode([PodcastData].self, from: data) {
            subscribedPodcasts = decodedPodcasts.map { $0.toPodcast() }
        }
    }
    
    private func savePodcastsToStorage() {
        let podcastData = subscribedPodcasts.map { PodcastData(from: $0) }
        if let encoded = try? JSONEncoder().encode(podcastData) {
            userDefaults.set(encoded, forKey: podcastsKey)
        }
    }
    
    private func loadSamplePodcasts() {
        let samplePodcasts = createSamplePodcasts()
        subscribedPodcasts = samplePodcasts
        savePodcastsToStorage()
    }
    
    private func createSamplePodcasts() -> [Podcast] {
        var podcasts: [Podcast] = []
        
        // Sample Podcast 1: 朝活ラジオ
        let morningEpisodes = createSampleEpisodes(
            podcastName: "朝活パパラジオ",
            episodeTitles: [
                "第1回：朝活を始めるコツ",
                "第2回：効率的な時間管理術", 
                "第3回：家族との時間を大切にする方法"
            ],
            baseDuration: 1800 // 30分
        )
        
        let morningPodcast = Podcast(
            name: "朝活パパラジオ",
            description: "朝活を頑張るパパエンジニアのための番組です。家族、仕事、プログラミングについて毎週お話しします。",
            author: "朝活パパエンジニア",
            category: "教育",
            episodes: morningEpisodes,
            isSubscribed: true
        )
        podcasts.append(morningPodcast)
        
        // Sample Podcast 2: テックトーク
        let techEpisodes = createSampleEpisodes(
            podcastName: "エンジニア朝トーク",
            episodeTitles: [
                "SwiftUI最新情報",
                "iOS開発のベストプラクティス",
                "プログラマーの朝活習慣"
            ],
            baseDuration: 2400 // 40分
        )
        
        let techPodcast = Podcast(
            name: "エンジニア朝トーク", 
            description: "エンジニアリングと朝活をテーマにした技術系ポッドキャストです。",
            author: "テックトーカー",
            category: "テクノロジー",
            episodes: techEpisodes,
            isSubscribed: true
        )
        podcasts.append(techPodcast)
        
        // Sample Podcast 3: ライフスタイル
        let lifestyleEpisodes = createSampleEpisodes(
            podcastName: "パパのライフハック",
            episodeTitles: [
                "朝の習慣で人生が変わる",
                "育児と仕事の両立術",
                "健康的な朝食のススメ"
            ],
            baseDuration: 1200 // 20分
        )
        
        let lifestylePodcast = Podcast(
            name: "パパのライフハック",
            description: "忙しいパパのためのライフスタイル改善番組です。",
            author: "ライフハックパパ",
            category: "ライフスタイル",
            episodes: lifestyleEpisodes,
            isSubscribed: true
        )
        podcasts.append(lifestylePodcast)
        
        return podcasts
    }
    
    private func createSampleEpisodes(podcastName: String, episodeTitles: [String], baseDuration: TimeInterval) -> [PodcastEpisode] {
        return episodeTitles.enumerated().map { (index, title) in
            let variation = Double.random(in: 0.8...1.2)
            let duration = baseDuration * variation
            let publishDate = Calendar.current.date(byAdding: .day, value: -(episodeTitles.count - index - 1) * 7, to: Date()) ?? Date()
            
            // Create dummy audio file URL (in real app, these would be actual files)
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let audioFileName = "\(podcastName)_\(index + 1).mp3"
            let audioURL = documentsPath.appendingPathComponent(audioFileName)
            
            // Create some sample episodes with different playback states
            let playbackPosition: TimeInterval
            let isPlayed: Bool
            
            switch index {
            case 0:
                // First episode - fully played
                playbackPosition = duration
                isPlayed = true
            case 1:
                // Second episode - partially played
                playbackPosition = duration * 0.3
                isPlayed = false
            default:
                // Other episodes - not started
                playbackPosition = 0
                isPlayed = false
            }
            
            return PodcastEpisode(
                title: title,
                description: "\(title)についての詳細な内容をお届けします。朝活をテーマに、実践的なアドバイスや経験談を共有します。",
                duration: duration,
                filePath: audioURL,
                podcastName: podcastName,
                publishDate: publishDate,
                playbackPosition: playbackPosition,
                isPlayed: isPlayed,
                episodeNumber: index + 1
            )
        }
    }
    
    // MARK: - Audio File Utilities
    
    func getAudioDuration(from url: URL) -> TimeInterval {
        let asset = AVAsset(url: url)
        let duration = asset.duration
        return CMTimeGetSeconds(duration)
    }
    
    func extractArtwork(from url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let metadataItems = asset.metadata
        
        for item in metadataItems {
            if item.commonKey == .commonKeyArtwork,
               let data = item.dataValue,
               let image = UIImage(data: data) {
                return image
            }
        }
        return nil
    }
    
    func extractMetadata(from url: URL) -> (title: String?, artist: String?, album: String?) {
        let asset = AVAsset(url: url)
        let metadataItems = asset.metadata
        
        var title: String?
        var artist: String?
        var album: String?
        
        for item in metadataItems {
            switch item.commonKey {
            case .commonKeyTitle:
                title = item.stringValue
            case .commonKeyArtist:
                artist = item.stringValue
            case .commonKeyAlbumName:
                album = item.stringValue
            default:
                break
            }
        }
        
        return (title, artist, album)
    }
}

// MARK: - Codable Data Models

private struct PodcastData: Codable {
    let id: String
    let name: String
    let description: String
    let author: String
    let category: String
    let language: String
    let subscriptionDate: Date
    let episodes: [PodcastEpisodeData]
    let isSubscribed: Bool
    let autoDownload: Bool
    let playbackRate: Float
    let feedURLString: String?
    
    init(from podcast: Podcast) {
        self.id = podcast.id.uuidString
        self.name = podcast.name
        self.description = podcast.description
        self.author = podcast.author
        self.category = podcast.category
        self.language = podcast.language
        self.subscriptionDate = podcast.subscriptionDate
        self.episodes = podcast.episodes.map { PodcastEpisodeData(from: $0) }
        self.isSubscribed = podcast.isSubscribed
        self.autoDownload = podcast.autoDownload
        self.playbackRate = podcast.playbackRate
        self.feedURLString = podcast.feedURL?.absoluteString
    }
    
    func toPodcast() -> Podcast {
        let feedURL = feedURLString.flatMap { URL(string: $0) }
        let podcastEpisodes = episodes.map { $0.toPodcastEpisode() }
        
        return Podcast(
            name: name,
            description: description,
            author: author,
            category: category,
            language: language,
            artwork: nil, // Artwork not persisted for simplicity
            episodes: podcastEpisodes,
            isSubscribed: isSubscribed,
            autoDownload: autoDownload,
            playbackRate: playbackRate,
            feedURL: feedURL
        )
    }
}

private struct PodcastEpisodeData: Codable {
    let id: String
    let title: String
    let description: String
    let duration: TimeInterval
    let filePathString: String
    let podcastName: String
    let author: String
    let publishDate: Date
    let playbackPosition: TimeInterval
    let isPlayed: Bool
    let isBookmarked: Bool
    let episodeNumber: Int?
    let seasonNumber: Int?
    
    init(from episode: PodcastEpisode) {
        self.id = episode.id.uuidString
        self.title = episode.title
        self.description = episode.description
        self.duration = episode.duration
        self.filePathString = episode.filePath.absoluteString
        self.podcastName = episode.podcastName
        self.author = episode.author
        self.publishDate = episode.publishDate
        self.playbackPosition = episode.playbackPosition
        self.isPlayed = episode.isPlayed
        self.isBookmarked = episode.isBookmarked
        self.episodeNumber = episode.episodeNumber
        self.seasonNumber = episode.seasonNumber
    }
    
    func toPodcastEpisode() -> PodcastEpisode {
        let filePath = URL(string: filePathString) ?? URL(fileURLWithPath: "/tmp/unknown.mp3")
        
        return PodcastEpisode(
            title: title,
            description: description,
            duration: duration,
            filePath: filePath,
            podcastName: podcastName,
            author: author,
            publishDate: publishDate,
            artwork: nil, // Artwork not persisted for simplicity
            playbackPosition: playbackPosition,
            isPlayed: isPlayed,
            isBookmarked: isBookmarked,
            episodeNumber: episodeNumber,
            seasonNumber: seasonNumber
        )
    }
}