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
            Task {
                await loadSamplePodcasts()
                await MainActor.run {
                    isLoading = false
                }
            }
        } else {
            isLoading = false
        }
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
    
    private func loadSamplePodcasts() async {
        // まずバンドルから実際の音声ファイルを読み込む
        let bundledPodcasts = await loadBundledAudioFiles()

        if !bundledPodcasts.isEmpty {
            // 実際のファイルが見つかった場合はそれを使用
            subscribedPodcasts = bundledPodcasts
        } else {
            // 実際のファイルがない場合はサンプルデータを使用
            let samplePodcasts = await createSamplePodcasts()
            subscribedPodcasts = samplePodcasts
        }
        savePodcastsToStorage()
    }

    private func loadBundledAudioFiles() async -> [Podcast] {
        var podcasts: [Podcast] = []
        let fileManager = FileManager.default

        // バンドルからsoundディレクトリのURLを取得（複数の方法を試す）
        var soundURL: URL?

        // 方法1: Bundle.main.resourceURL?.appendingPathComponent("sound") - 最も確実
        if let resourceURL = Bundle.main.resourceURL {
            let candidateURL = resourceURL.appendingPathComponent("sound")
            if fileManager.fileExists(atPath: candidateURL.path) {
                soundURL = candidateURL
                print("✅ soundディレクトリ発見（resourceURL）: \(candidateURL.path)")
            } else {
                print("⚠️ soundディレクトリが存在しません（resourceURL）: \(candidateURL.path)")
            }
        } else {
            print("❌ Bundle.main.resourceURLが取得できません")
        }

        // 方法2: Bundle.main.url(forResource:withExtension:)
        if soundURL == nil, let url = Bundle.main.url(forResource: "sound", withExtension: nil) {
            soundURL = url
            print("✅ soundディレクトリ発見（forResource）: \(url.path)")
        }

        // 方法3: Bundle.main.bundlePath を使用
        if soundURL == nil {
            let bundlePath = Bundle.main.bundlePath
            let candidateURL = URL(fileURLWithPath: bundlePath).appendingPathComponent("sound")
            if fileManager.fileExists(atPath: candidateURL.path) {
                soundURL = candidateURL
                print("✅ soundディレクトリ発見（bundlePath）: \(candidateURL.path)")
            }
        }

        guard let finalSoundURL = soundURL else {
            print("❌ soundディレクトリが見つかりません")
            print("📋 Bundle情報:")
            print("  - bundlePath: \(Bundle.main.bundlePath)")
            print("  - resourcePath: \(Bundle.main.resourcePath ?? "nil")")
            print("  - resourceURL: \(Bundle.main.resourceURL?.path ?? "nil")")
            return []
        }

        // soundディレクトリ内の音声ファイルを検索
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
            // async関数を呼び出し
            let duration = await getAudioDuration(from: audioURL)
            let metadata = await extractMetadata(from: audioURL)
            let artwork = await extractArtwork(from: audioURL)

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
    
    private func createSamplePodcasts() async -> [Podcast] {
        var podcasts: [Podcast] = []

        // Sample Podcast 1: 朝活ラジオ
        let morningEpisodes = await createSampleEpisodes(
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
        let techEpisodes = await createSampleEpisodes(
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
        let lifestyleEpisodes = await createSampleEpisodes(
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
    
    private func createSampleEpisodes(podcastName: String, episodeTitles: [String], baseDuration: TimeInterval) async -> [PodcastEpisode] {
        var episodes: [PodcastEpisode] = []

        for (index, title) in episodeTitles.enumerated() {
            let publishDate = Calendar.current.date(byAdding: .day, value: -(episodeTitles.count - index - 1) * 7, to: Date()) ?? Date()

            // Create dummy audio file URL (in real app, these would be actual files)
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let audioFileName = "\(podcastName)_\(index + 1).caf"
            let audioURL = documentsPath.appendingPathComponent(audioFileName)

            // Ensure silent audio placeholder exists so playback does not fail
            let preferredSampleDuration: TimeInterval = min(baseDuration, 300) // 最大5分の無音音声
            let actualDuration = await ensureSampleAudioFile(at: audioURL, preferredDuration: preferredSampleDuration)
            let duration = actualDuration > 0 ? actualDuration : preferredSampleDuration
            
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

            let episode = PodcastEpisode(
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

            episodes.append(episode)
        }

        return episodes
    }
    
    @discardableResult
    private func ensureSampleAudioFile(at url: URL, preferredDuration: TimeInterval) async -> TimeInterval {
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: url.path) {
            do {
                let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
                guard let format = format else {
                    throw NSError(domain: "PodcastLibraryManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "AVAudioFormatの生成に失敗しました"])
                }
                
                let directory = url.deletingLastPathComponent()
                if !fileManager.fileExists(atPath: directory.path) {
                    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
                }
                
                let audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
                let totalFrames = AVAudioFrameCount(preferredDuration * format.sampleRate)
                let chunkSize = min(totalFrames, AVAudioFrameCount(format.sampleRate)) // 1秒単位で書き込み
                
                var framesRemaining = totalFrames
                while framesRemaining > 0 {
                    let framesToWrite = min(framesRemaining, chunkSize)
                    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: framesToWrite) else {
                        throw NSError(domain: "PodcastLibraryManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "AVAudioPCMBufferの生成に失敗しました"])
                    }
                    buffer.frameLength = framesToWrite
                    try audioFile.write(from: buffer)
                    framesRemaining -= framesToWrite
                }
            } catch {
                print("❌ サンプル音声ファイルの生成に失敗しました: \(error.localizedDescription)")
                return 0
            }
        }
        
        let asset = AVAsset(url: url)
        // iOS 16+ の新しいAPI使用
        if let duration = try? await asset.load(.duration) {
            let seconds = CMTimeGetSeconds(duration)
            return seconds.isFinite ? seconds : 0
        }
        return 0
    }
    
    // MARK: - Audio File Utilities

    func getAudioDuration(from url: URL) async -> TimeInterval {
        let asset = AVAsset(url: url)

        // iOS 16+ の新しいAPI使用
        do {
            let duration = try await asset.load(.duration)
            return CMTimeGetSeconds(duration)
        } catch {
            print("⚠️ デュレーション取得エラー: \(error.localizedDescription)")
            return 0
        }
    }

    func extractArtwork(from url: URL) async -> UIImage? {
        let asset = AVAsset(url: url)

        // iOS 16+ の新しいAPI使用
        do {
            let metadataItems = try await asset.load(.metadata)

            for item in metadataItems {
                guard let commonKey = try? await item.load(.commonKey) else { continue }

                if commonKey == .commonKeyArtwork {
                    if let data = try? await item.load(.dataValue),
                       let image = UIImage(data: data) {
                        return image
                    }
                }
            }
        } catch {
            print("⚠️ アートワーク取得エラー: \(error.localizedDescription)")
        }

        return nil
    }

    func extractMetadata(from url: URL) async -> (title: String?, artist: String?, album: String?) {
        let asset = AVAsset(url: url)

        var title: String?
        var artist: String?
        var album: String?

        // iOS 16+ の新しいAPI使用
        do {
            let metadataItems = try await asset.load(.metadata)

            for item in metadataItems {
                guard let commonKey = try? await item.load(.commonKey) else { continue }

                switch commonKey {
                case .commonKeyTitle:
                    title = try? await item.load(.stringValue)
                case .commonKeyArtist:
                    artist = try? await item.load(.stringValue)
                case .commonKeyAlbumName:
                    album = try? await item.load(.stringValue)
                default:
                    break
                }
            }
        } catch {
            print("⚠️ メタデータ取得エラー: \(error.localizedDescription)")
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
        let podcastId = UUID(uuidString: id) ?? UUID()  // 保存されたUUIDを復元

        return Podcast(
            id: podcastId,  // 保存されたIDを使用
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
    let filePathString: String?
    let bundleRelativePath: String?
    let isBundledResource: Bool
    let podcastName: String
    let author: String
    let publishDate: Date
    let playbackPosition: TimeInterval
    let isPlayed: Bool
    let isBookmarked: Bool
    let episodeNumber: Int?
    let seasonNumber: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case duration
        case filePathString
        case bundleRelativePath
        case isBundledResource
        case podcastName
        case author
        case publishDate
        case playbackPosition
        case isPlayed
        case isBookmarked
        case episodeNumber
        case seasonNumber
    }
    
    init(from episode: PodcastEpisode) {
        self.id = episode.id.uuidString
        self.title = episode.title
        self.description = episode.description
        self.duration = episode.duration
        self.podcastName = episode.podcastName
        self.author = episode.author
        self.publishDate = episode.publishDate
        self.playbackPosition = episode.playbackPosition
        self.isPlayed = episode.isPlayed
        self.isBookmarked = episode.isBookmarked
        self.episodeNumber = episode.episodeNumber
        self.seasonNumber = episode.seasonNumber
        
        let standardizedFileURL = episode.filePath.standardizedFileURL
        if let bundleURL = Bundle.main.resourceURL?.standardizedFileURL,
           standardizedFileURL.path.hasPrefix(bundleURL.path) {
            self.isBundledResource = true
            let relativePath = String(standardizedFileURL.path.dropFirst(bundleURL.path.count + 1))
            self.bundleRelativePath = relativePath
            self.filePathString = nil
        } else {
            self.isBundledResource = false
            self.bundleRelativePath = nil
            self.filePathString = standardizedFileURL.absoluteString
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.duration = try container.decode(TimeInterval.self, forKey: .duration)
        self.filePathString = try container.decodeIfPresent(String.self, forKey: .filePathString)
        self.bundleRelativePath = try container.decodeIfPresent(String.self, forKey: .bundleRelativePath)
        self.isBundledResource = try container.decodeIfPresent(Bool.self, forKey: .isBundledResource) ?? false
        self.podcastName = try container.decode(String.self, forKey: .podcastName)
        self.author = try container.decode(String.self, forKey: .author)
        self.publishDate = try container.decode(Date.self, forKey: .publishDate)
        self.playbackPosition = try container.decode(TimeInterval.self, forKey: .playbackPosition)
        self.isPlayed = try container.decode(Bool.self, forKey: .isPlayed)
        self.isBookmarked = try container.decode(Bool.self, forKey: .isBookmarked)
        self.episodeNumber = try container.decodeIfPresent(Int.self, forKey: .episodeNumber)
        self.seasonNumber = try container.decodeIfPresent(Int.self, forKey: .seasonNumber)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(duration, forKey: .duration)
        try container.encodeIfPresent(filePathString, forKey: .filePathString)
        try container.encodeIfPresent(bundleRelativePath, forKey: .bundleRelativePath)
        try container.encode(isBundledResource, forKey: .isBundledResource)
        try container.encode(podcastName, forKey: .podcastName)
        try container.encode(author, forKey: .author)
        try container.encode(publishDate, forKey: .publishDate)
        try container.encode(playbackPosition, forKey: .playbackPosition)
        try container.encode(isPlayed, forKey: .isPlayed)
        try container.encode(isBookmarked, forKey: .isBookmarked)
        try container.encodeIfPresent(episodeNumber, forKey: .episodeNumber)
        try container.encodeIfPresent(seasonNumber, forKey: .seasonNumber)
    }
    
    func toPodcastEpisode() -> PodcastEpisode {
        let filePath = resolveFileURL()
        let episodeId = UUID(uuidString: id) ?? UUID()  // 保存されたUUIDを復元

        return PodcastEpisode(
            id: episodeId,  // 保存されたIDを使用
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
    
    private func resolveFileURL() -> URL {
        let fileManager = FileManager.default
        
        // 1. Stored absolute path still valid
        if let filePathString,
           let storedURL = URL(string: filePathString),
           storedURL.isFileURL,
           fileManager.fileExists(atPath: storedURL.path) {
            return storedURL
        }
        
        // 2. Bundled resource using stored relative path
        if let bundleURL = Bundle.main.resourceURL {
            if let relativePath = bundleRelativePath {
                let candidate = bundleURL.appendingPathComponent(relativePath)
                if fileManager.fileExists(atPath: candidate.path) {
                    return candidate
                }
                
                if let searchResult = searchBundledResource(relativePath: relativePath) {
                    return searchResult
                }
            }
            
            // 3. Legacy absolute path pointing into previous bundle location
            if let legacyURL = legacyBundleURL(from: filePathString, bundleBase: bundleURL) {
                return legacyURL
            }
        }
        
        // 4. Documents directory fallback
        if let fileName = extractFileName(),
           let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let candidate = documentsDirectory.appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        
        return URL(fileURLWithPath: "/tmp/unknown.mp3")
    }
    
    private func extractFileName() -> String? {
        if let relativePath = bundleRelativePath {
            return URL(fileURLWithPath: relativePath).lastPathComponent
        }
        
        if let filePathString,
           let storedURL = URL(string: filePathString),
           storedURL.isFileURL {
            return storedURL.lastPathComponent
        }
        
        if let filePathString, filePathString.hasPrefix("/") {
            return URL(fileURLWithPath: filePathString).lastPathComponent
        }
        
        return nil
    }
    
    private func legacyBundleURL(from pathString: String?, bundleBase: URL) -> URL? {
        guard let pathString = pathString else { return nil }
        
        let possibleURL: URL
        if let url = URL(string: pathString), url.isFileURL {
            possibleURL = url.standardizedFileURL
        } else if pathString.hasPrefix("/") {
            possibleURL = URL(fileURLWithPath: pathString).standardizedFileURL
        } else {
            return nil
        }
        
        let standardizedPath = possibleURL.path
        guard let range = standardizedPath.range(of: ".app/") else { return nil }
        let relativePath = String(standardizedPath[range.upperBound...])
        let candidate = bundleBase.appendingPathComponent(relativePath)
        if FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }
        
        return searchBundledResource(relativePath: relativePath)
    }
    
    private func searchBundledResource(relativePath: String) -> URL? {
        let fileName = URL(fileURLWithPath: relativePath).lastPathComponent
        let fileBase = (fileName as NSString).deletingPathExtension
        let fileExtension = (fileName as NSString).pathExtension
        
        if !fileExtension.isEmpty,
           let url = Bundle.main.url(forResource: fileBase, withExtension: fileExtension, subdirectory: "sound") {
            return url
        }
        
        if !fileExtension.isEmpty,
           let url = Bundle.main.url(forResource: fileBase, withExtension: fileExtension) {
            return url
        }
        
        return nil
    }
}
