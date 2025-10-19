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
        // まずバンドルから実際の音声ファイルを読み込む
        let bundledPodcasts = loadBundledAudioFiles()

        if !bundledPodcasts.isEmpty {
            // 実際のファイルが見つかった場合はそれを使用
            subscribedPodcasts = bundledPodcasts
        } else {
            // 実際のファイルがない場合はサンプルデータを使用
            let samplePodcasts = createSamplePodcasts()
            subscribedPodcasts = samplePodcasts
        }
        savePodcastsToStorage()
    }

    private func loadBundledAudioFiles() -> [Podcast] {
        var podcasts: [Podcast] = []

        // バンドルからsoundディレクトリのURLを取得（複数の方法を試す）
        var soundURL: URL?

        // 方法1: Bundle.main.url(forResource:withExtension:)
        if let url = Bundle.main.url(forResource: "sound", withExtension: nil) {
            soundURL = url
            print("✅ soundディレクトリ発見（方法1）: \(url.path)")
        }
        // 方法2: Bundle.main.resourceURL?.appendingPathComponent("sound")
        else if let url = Bundle.main.resourceURL?.appendingPathComponent("sound") {
            soundURL = url
            print("✅ soundディレクトリ発見（方法2）: \(url.path)")
        }
        // 方法3: Bundle.main.bundleURL.appendingPathComponent("sound")
        else if let url = try? Bundle.main.bundleURL.appendingPathComponent("sound", isDirectory: true) {
            soundURL = url
            print("✅ soundディレクトリ発見（方法3）: \(url.path)")
        }

        guard let finalSoundURL = soundURL else {
            print("❌ soundディレクトリが見つかりません")
            print("Bundle.main.bundlePath: \(Bundle.main.bundlePath)")
            print("Bundle.main.resourcePath: \(Bundle.main.resourcePath ?? "nil")")
            return []
        }

        // soundディレクトリ内の音声ファイルを検索
        let fileManager = FileManager.default

        // ディレクトリが存在するか確認
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: finalSoundURL.path, isDirectory: &isDirectory)
        print("📁 soundディレクトリ存在確認: exists=\(exists), isDirectory=\(isDirectory.boolValue)")

        guard let audioFiles = try? fileManager.contentsOfDirectory(
            at: finalSoundURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            print("❌ soundディレクトリの読み取りに失敗しました: \(finalSoundURL.path)")
            return []
        }

        print("📂 soundディレクトリ内のファイル数: \(audioFiles.count)")

        // 対応する音声形式のファイルをフィルタリング
        let supportedExtensions = ["m4a", "mp3", "mp4", "aac"]
        let audioFileURLs = audioFiles.filter { url in
            supportedExtensions.contains(url.pathExtension.lowercased())
        }

        guard !audioFileURLs.isEmpty else {
            print("❌ 対応する音声ファイルが見つかりません")
            print("📋 全ファイル: \(audioFiles.map { $0.lastPathComponent })")
            return []
        }

        print("🎵 対応する音声ファイル数: \(audioFileURLs.count)")

        // 各音声ファイルからエピソードを作成
        var episodes: [PodcastEpisode] = []

        for audioURL in audioFileURLs {
            let duration = getAudioDuration(from: audioURL)
            let metadata = extractMetadata(from: audioURL)
            let artwork = extractArtwork(from: audioURL)

            // ファイル名から拡張子を除いたものをタイトルとして使用（メタデータがない場合）
            let fileName = audioURL.deletingPathExtension().lastPathComponent
            let title = metadata.title ?? fileName
            let author = metadata.artist ?? "朝活パパエンジニア"

            let episode = PodcastEpisode(
                title: title,
                description: "\(title)についてのエピソードです。朝活パパによるポッドキャスト配信です。",
                duration: duration,
                filePath: audioURL,
                podcastName: "朝活パパラジオ",
                author: author,
                publishDate: Date(),
                artwork: artwork,
                playbackPosition: 0,
                isPlayed: false,
                isBookmarked: false,
                episodeNumber: episodes.count + 1
            )

            episodes.append(episode)
            print("✅ エピソード読み込み: \(title) (デュレーション: \(formatDuration(duration)))")
        }

        // エピソードをPodcastにまとめる
        if !episodes.isEmpty {
            let podcast = Podcast(
                name: "朝活パパラジオ",
                description: "朝活を頑張るパパエンジニアのための番組です。家族、仕事、プログラミングについてお話しします。",
                author: "朝活パパエンジニア",
                category: "教育",
                episodes: episodes,
                isSubscribed: true
            )
            podcasts.append(podcast)
            print("🎙️ ポッドキャスト作成完了: \(episodes.count)個のエピソード")
        } else {
            print("⚠️ エピソードが0個のため、ポッドキャストを作成しませんでした")
        }

        return podcasts
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
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