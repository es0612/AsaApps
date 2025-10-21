import Foundation
import UIKit

struct PodcastEpisode: Identifiable, Equatable {
    var id: UUID  // letからvarに変更してIDを保持可能に
    let title: String
    let description: String
    let duration: TimeInterval
    let filePath: URL
    let podcastName: String
    let author: String
    let publishDate: Date
    let artwork: UIImage?
    var playbackPosition: TimeInterval
    var isPlayed: Bool
    var isBookmarked: Bool
    let episodeNumber: Int?
    let seasonNumber: Int?

    init(
        id: UUID = UUID(),  // デフォルトで新しいUUIDを生成
        title: String,
        description: String = "",
        duration: TimeInterval,
        filePath: URL,
        podcastName: String,
        author: String = "不明なポッドキャスター",
        publishDate: Date = Date(),
        artwork: UIImage? = nil,
        playbackPosition: TimeInterval = 0,
        isPlayed: Bool = false,
        isBookmarked: Bool = false,
        episodeNumber: Int? = nil,
        seasonNumber: Int? = nil
    ) {
        self.id = id  // IDを引数から設定
        self.title = title
        self.description = description
        self.duration = duration
        self.filePath = filePath
        self.podcastName = podcastName
        self.author = author
        self.publishDate = publishDate
        self.artwork = artwork
        self.playbackPosition = playbackPosition
        self.isPlayed = isPlayed
        self.isBookmarked = isBookmarked
        self.episodeNumber = episodeNumber
        self.seasonNumber = seasonNumber
    }
    
    // MARK: - Computed Properties
    
    var displayTitle: String {
        if title.isEmpty {
            return filePath.lastPathComponent.replacingOccurrences(of: "." + filePath.pathExtension, with: "")
        }
        return title
    }
    
    var displayDescription: String {
        return description.isEmpty ? "説明はありません" : description
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var formattedPlaybackPosition: String {
        let hours = Int(playbackPosition) / 3600
        let minutes = (Int(playbackPosition) % 3600) / 60
        let seconds = Int(playbackPosition) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var remainingTime: TimeInterval {
        return max(0, duration - playbackPosition)
    }
    
    var formattedRemainingTime: String {
        let remaining = remainingTime
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60
        
        if hours > 0 {
            return String(format: "残り %d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "残り %d:%02d", minutes, seconds)
        }
    }
    
    var playbackProgress: Double {
        guard duration > 0 else { return 0 }
        return playbackPosition / duration
    }
    
    var episodeDisplayName: String {
        var components: [String] = []
        
        if let season = seasonNumber {
            components.append("シーズン\(season)")
        }
        
        if let episode = episodeNumber {
            components.append("第\(episode)話")
        }
        
        if !components.isEmpty {
            return components.joined(separator: " ") + ": " + displayTitle
        }
        
        return displayTitle
    }
    
    var formattedPublishDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: publishDate)
    }
    
    // MARK: - Methods
    
    mutating func markAsPlayed() {
        isPlayed = true
        playbackPosition = duration
    }
    
    mutating func markAsUnplayed() {
        isPlayed = false
        playbackPosition = 0
    }
    
    mutating func updatePlaybackPosition(_ position: TimeInterval) {
        playbackPosition = max(0, min(position, duration))
        
        // 90%以上再生した場合は再生済みとしてマーク
        if playbackProgress >= 0.9 {
            isPlayed = true
        }
    }
    
    mutating func toggleBookmark() {
        isBookmarked.toggle()
    }
    
    // MARK: - Equatable
    
    static func == (lhs: PodcastEpisode, rhs: PodcastEpisode) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Podcast Status Enums

enum PlaybackState: String, CaseIterable {
    case notStarted = "notStarted"
    case inProgress = "inProgress"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .notStarted: return "未再生"
        case .inProgress: return "再生中"
        case .completed: return "再生済み"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .notStarted: return "circle"
        case .inProgress: return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
}

enum EpisodePriority: String, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "低"
        case .normal: return "通常"
        case .high: return "高"
        }
    }
}