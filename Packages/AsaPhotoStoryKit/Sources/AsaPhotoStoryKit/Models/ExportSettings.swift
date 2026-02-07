import Foundation

// MARK: - ExportSettings

/// エクスポート設定
public struct ExportSettings: Codable, Equatable, Sendable {
    // MARK: - Properties

    public var format: ExportFormat
    public var resolution: ExportResolution
    public var includeAudio: Bool
    public var quality: Double

    // MARK: - Initializer

    public init(
        format: ExportFormat = .video,
        resolution: ExportResolution = .hd1080p,
        includeAudio: Bool = false,
        quality: Double = 0.8
    ) {
        self.format = format
        self.resolution = resolution
        self.includeAudio = includeAudio
        self.quality = quality
    }

    // MARK: - Default

    public static let `default` = ExportSettings()
}

// MARK: - ExportFormat

/// エクスポート形式
public enum ExportFormat: String, CaseIterable, Codable, Sendable {
    case images
    case pdf
    case video

    public var displayName: String {
        switch self {
        case .images: "画像"
        case .pdf: "PDF"
        case .video: "動画"
        }
    }

    public var fileExtension: String {
        switch self {
        case .images: "png"
        case .pdf: "pdf"
        case .video: "mp4"
        }
    }
}

// MARK: - ExportResolution

/// エクスポート解像度
public enum ExportResolution: String, CaseIterable, Codable, Sendable {
    case hd1080p
    case hd1440p
    case uhd4K

    public var displayName: String {
        switch self {
        case .hd1080p: "1080p (Full HD)"
        case .hd1440p: "1440p (QHD)"
        case .uhd4K: "4K (UHD)"
        }
    }

    public var width: Int {
        switch self {
        case .hd1080p: 1920
        case .hd1440p: 2560
        case .uhd4K: 3840
        }
    }

    public var height: Int {
        switch self {
        case .hd1080p: 1080
        case .hd1440p: 1440
        case .uhd4K: 2160
        }
    }
}
