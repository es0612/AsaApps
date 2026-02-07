import Foundation

// MARK: - PhotoStoryError

/// AsaPhotoStory全体のエラー定義
public enum PhotoStoryError: Error, LocalizedError, Sendable {
    case storyNotFound
    case pageNotFound
    case elementNotFound
    case imageLoadFailed
    case imageSaveFailed
    case imageResizeFailed
    case exportFailed(String)
    case captionGenerationFailed
    case invalidTemplate
    case invalidLayout
    case dataCorruption
    case photoPickerFailed
    case visionAnalysisFailed

    public var errorDescription: String? {
        switch self {
        case .storyNotFound:
            "ストーリーが見つかりません"
        case .pageNotFound:
            "ページが見つかりません"
        case .elementNotFound:
            "要素が見つかりません"
        case .imageLoadFailed:
            "画像の読み込みに失敗しました"
        case .imageSaveFailed:
            "画像の保存に失敗しました"
        case .imageResizeFailed:
            "画像のリサイズに失敗しました"
        case .exportFailed(let detail):
            "エクスポートに失敗しました: \(detail)"
        case .captionGenerationFailed:
            "キャプションの生成に失敗しました"
        case .invalidTemplate:
            "無効なテンプレートです"
        case .invalidLayout:
            "無効なレイアウトです"
        case .dataCorruption:
            "データが破損しています"
        case .photoPickerFailed:
            "写真の選択に失敗しました"
        case .visionAnalysisFailed:
            "画像分析に失敗しました"
        }
    }
}
