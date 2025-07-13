import Foundation
import UIKit

struct MusicTrack: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let artist: String
    let album: String?
    let duration: TimeInterval
    let filePath: URL
    let artwork: UIImage?
    let dateAdded: Date
    
    init(title: String, artist: String, album: String? = nil, duration: TimeInterval, filePath: URL, artwork: UIImage? = nil) {
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.filePath = filePath
        self.artwork = artwork
        self.dateAdded = Date()
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var displayTitle: String {
        return title.isEmpty ? filePath.lastPathComponent : title
    }
    
    var displayArtist: String {
        return artist.isEmpty ? "不明なアーティスト" : artist
    }
    
    static func == (lhs: MusicTrack, rhs: MusicTrack) -> Bool {
        return lhs.id == rhs.id
    }
}

enum MusicPlayerState: String, CaseIterable {
    case stopped = "stopped"
    case playing = "playing"
    case paused = "paused"
    case loading = "loading"
    
    var isPlaying: Bool {
        return self == .playing
    }
    
    var isPaused: Bool {
        return self == .paused
    }
    
    var isStopped: Bool {
        return self == .stopped
    }
    
    var isLoading: Bool {
        return self == .loading
    }
}

enum RepeatMode: String, CaseIterable {
    case none = "none"
    case all = "all"
    case one = "one"
    
    var displayName: String {
        switch self {
        case .none: return "リピートなし"
        case .all: return "全曲リピート"
        case .one: return "1曲リピート"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .none: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }
}