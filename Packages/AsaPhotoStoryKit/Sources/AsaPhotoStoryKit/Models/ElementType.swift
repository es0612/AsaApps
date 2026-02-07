import Foundation

// MARK: - ElementType

/// ストーリー要素の種類
public enum ElementType: String, CaseIterable, Codable, Sendable {
    case photo
    case text
    case sticker
    case drawing

    // MARK: - Properties

    public var displayName: String {
        switch self {
        case .photo: "写真"
        case .text: "テキスト"
        case .sticker: "スタンプ"
        case .drawing: "手描き"
        }
    }

    public var iconName: String {
        switch self {
        case .photo: "photo"
        case .text: "textformat"
        case .sticker: "face.smiling"
        case .drawing: "pencil.tip"
        }
    }
}
