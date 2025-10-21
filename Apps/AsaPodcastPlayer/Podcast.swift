import Foundation
import UIKit

struct Podcast: Identifiable, Equatable {
    var id: UUID  // letからvarに変更してIDを保持可能に
    let name: String
    let description: String
    let author: String
    let category: String
    let language: String
    let artwork: UIImage?
    let subscriptionDate: Date
    var episodes: [PodcastEpisode]
    var isSubscribed: Bool
    var autoDownload: Bool
    var playbackRate: Float
    let feedURL: URL?

    init(
        id: UUID = UUID(),  // デフォルトで新しいUUIDを生成
        name: String,
        description: String = "",
        author: String,
        category: String = "一般",
        language: String = "ja",
        artwork: UIImage? = nil,
        episodes: [PodcastEpisode] = [],
        isSubscribed: Bool = false,
        autoDownload: Bool = false,
        playbackRate: Float = 1.0,
        feedURL: URL? = nil
    ) {
        self.id = id  // IDを引数から設定
        self.name = name
        self.description = description
        self.author = author
        self.category = category
        self.language = language
        self.artwork = artwork
        self.subscriptionDate = Date()
        self.episodes = episodes
        self.isSubscribed = isSubscribed
        self.autoDownload = autoDownload
        self.playbackRate = playbackRate
        self.feedURL = feedURL
    }
    
    // MARK: - Computed Properties
    
    var displayName: String {
        return name.isEmpty ? "不明なポッドキャスト" : name
    }
    
    var displayDescription: String {
        return description.isEmpty ? "説明はありません" : description
    }
    
    var displayAuthor: String {
        return author.isEmpty ? "不明なポッドキャスター" : author
    }
    
    var totalEpisodes: Int {
        return episodes.count
    }
    
    var playedEpisodes: Int {
        return episodes.filter { $0.isPlayed }.count
    }
    
    var unplayedEpisodes: Int {
        return episodes.filter { !$0.isPlayed }.count
    }
    
    var inProgressEpisodes: Int {
        return episodes.filter { $0.playbackPosition > 0 && !$0.isPlayed }.count
    }
    
    var bookmarkedEpisodes: [PodcastEpisode] {
        return episodes.filter { $0.isBookmarked }
    }
    
    var latestEpisode: PodcastEpisode? {
        return episodes.max { $0.publishDate < $1.publishDate }
    }
    
    var oldestEpisode: PodcastEpisode? {
        return episodes.min { $0.publishDate < $1.publishDate }
    }
    
    var totalDuration: TimeInterval {
        return episodes.reduce(0) { $0 + $1.duration }
    }
    
    var remainingDuration: TimeInterval {
        return episodes.reduce(0) { total, episode in
            total + episode.remainingTime
        }
    }
    
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%d時間%d分", hours, minutes)
        } else {
            return String(format: "%d分", minutes)
        }
    }
    
    var formattedRemainingDuration: String {
        let hours = Int(remainingDuration) / 3600
        let minutes = (Int(remainingDuration) % 3600) / 60
        
        if hours > 0 {
            return String(format: "残り%d時間%d分", hours, minutes)
        } else {
            return String(format: "残り%d分", minutes)
        }
    }
    
    var playbackProgress: Double {
        guard totalDuration > 0 else { return 0 }
        let playedDuration = episodes.reduce(0) { $0 + $1.playbackPosition }
        return playedDuration / totalDuration
    }
    
    var formattedSubscriptionDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: subscriptionDate)
    }
    
    // MARK: - Episode Management Methods
    
    mutating func addEpisode(_ episode: PodcastEpisode) {
        if !episodes.contains(episode) {
            episodes.append(episode)
            sortEpisodesByDate()
        }
    }
    
    mutating func removeEpisode(_ episode: PodcastEpisode) {
        episodes.removeAll { $0.id == episode.id }
    }
    
    mutating func updateEpisode(_ updatedEpisode: PodcastEpisode) {
        if let index = episodes.firstIndex(where: { $0.id == updatedEpisode.id }) {
            episodes[index] = updatedEpisode
        }
    }
    
    private mutating func sortEpisodesByDate() {
        episodes.sort { $0.publishDate > $1.publishDate }
    }
    
    func episodesSortedBy(_ sortOrder: EpisodeSortOrder) -> [PodcastEpisode] {
        switch sortOrder {
        case .dateNewest:
            return episodes.sorted { $0.publishDate > $1.publishDate }
        case .dateOldest:
            return episodes.sorted { $0.publishDate < $1.publishDate }
        case .titleAscending:
            return episodes.sorted { $0.displayTitle < $1.displayTitle }
        case .titleDescending:
            return episodes.sorted { $0.displayTitle > $1.displayTitle }
        case .durationShortest:
            return episodes.sorted { $0.duration < $1.duration }
        case .durationLongest:
            return episodes.sorted { $0.duration > $1.duration }
        case .playbackProgress:
            return episodes.sorted { $0.playbackProgress > $1.playbackProgress }
        }
    }
    
    func searchEpisodes(query: String) -> [PodcastEpisode] {
        guard !query.isEmpty else { return episodes }
        
        let lowercaseQuery = query.lowercased()
        return episodes.filter { episode in
            episode.displayTitle.lowercased().contains(lowercaseQuery) ||
            episode.displayDescription.lowercased().contains(lowercaseQuery)
        }
    }
    
    // MARK: - Subscription Methods
    
    mutating func subscribe() {
        isSubscribed = true
    }
    
    mutating func unsubscribe() {
        isSubscribed = false
        autoDownload = false
    }
    
    mutating func toggleAutoDownload() {
        autoDownload.toggle()
    }
    
    mutating func setPlaybackRate(_ rate: Float) {
        playbackRate = max(0.5, min(2.0, rate))
    }
    
    // MARK: - Analytics Methods
    
    var statistics: PodcastStatistics {
        return PodcastStatistics(
            totalEpisodes: totalEpisodes,
            playedEpisodes: playedEpisodes,
            inProgressEpisodes: inProgressEpisodes,
            totalListeningTime: episodes.reduce(0) { $0 + $1.playbackPosition },
            averageEpisodeDuration: totalEpisodes > 0 ? totalDuration / Double(totalEpisodes) : 0,
            subscriptionDate: subscriptionDate
        )
    }
    
    // MARK: - Equatable
    
    static func == (lhs: Podcast, rhs: Podcast) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Supporting Types

struct PodcastStatistics {
    let totalEpisodes: Int
    let playedEpisodes: Int
    let inProgressEpisodes: Int
    let totalListeningTime: TimeInterval
    let averageEpisodeDuration: TimeInterval
    let subscriptionDate: Date
    
    var formattedTotalListeningTime: String {
        let hours = Int(totalListeningTime) / 3600
        let minutes = (Int(totalListeningTime) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%d時間%d分", hours, minutes)
        } else {
            return String(format: "%d分", minutes)
        }
    }
    
    var formattedAverageEpisodeDuration: String {
        let minutes = Int(averageEpisodeDuration) / 60
        let seconds = Int(averageEpisodeDuration) % 60
        return String(format: "%d分%d秒", minutes, seconds)
    }
}

enum EpisodeSortOrder: String, CaseIterable {
    case dateNewest = "dateNewest"
    case dateOldest = "dateOldest"
    case titleAscending = "titleAscending"
    case titleDescending = "titleDescending"
    case durationShortest = "durationShortest"
    case durationLongest = "durationLongest"
    case playbackProgress = "playbackProgress"
    
    var displayName: String {
        switch self {
        case .dateNewest: return "新しい順"
        case .dateOldest: return "古い順"
        case .titleAscending: return "タイトル昇順"
        case .titleDescending: return "タイトル降順"
        case .durationShortest: return "短い順"
        case .durationLongest: return "長い順"
        case .playbackProgress: return "再生進捗順"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .dateNewest, .dateOldest: return "calendar"
        case .titleAscending, .titleDescending: return "textformat.abc"
        case .durationShortest, .durationLongest: return "clock"
        case .playbackProgress: return "chart.bar.fill"
        }
    }
}

enum PodcastCategory: String, CaseIterable {
    case technology = "technology"
    case business = "business"
    case education = "education"
    case entertainment = "entertainment"
    case news = "news"
    case health = "health"
    case science = "science"
    case history = "history"
    case comedy = "comedy"
    case music = "music"
    case sports = "sports"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .technology: return "テクノロジー"
        case .business: return "ビジネス"
        case .education: return "教育"
        case .entertainment: return "エンターテイメント"
        case .news: return "ニュース"
        case .health: return "健康"
        case .science: return "科学"
        case .history: return "歴史"
        case .comedy: return "コメディ"
        case .music: return "音楽"
        case .sports: return "スポーツ"
        case .other: return "その他"
        }
    }
}