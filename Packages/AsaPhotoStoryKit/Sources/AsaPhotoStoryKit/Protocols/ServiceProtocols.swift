import Foundation

// MARK: - StoryDataServiceProtocol

/// ストーリーデータのCRUD操作プロトコル（DI・テスト用）
@MainActor
public protocol StoryDataServiceProtocol: Sendable {
    /// ストーリー一覧を取得（検索・フィルタ対応）
    func fetchStories(searchText: String?, filterFavorites: Bool) throws -> [PhotoStory]

    /// ストーリーを作成
    func createStory(title: String, template: StoryTemplate, theme: StoryTheme) throws -> PhotoStory

    /// ストーリーを削除
    func deleteStory(_ story: PhotoStory) throws

    /// ストーリーを更新（変更を保存）
    func updateStory(_ story: PhotoStory) throws

    /// ページを追加
    func addPage(to story: PhotoStory, layout: PageLayout) throws -> StoryPage

    /// ページを削除
    func removePage(_ page: StoryPage, from story: PhotoStory) throws

    /// ページの順番を変更
    func reorderPages(in story: PhotoStory, fromIndex: Int, toIndex: Int) throws
}

// MARK: - ImageStorageServiceProtocol

/// 画像ファイル管理プロトコル（DI・テスト用）
public protocol ImageStorageServiceProtocol: Sendable {
    func saveImage(_ data: Data, filename: String) async throws -> URL
    func loadImage(filename: String) async throws -> Data
    func deleteImage(filename: String) async throws
    func resizeImage(_ data: Data, maxDimension: CGFloat) async throws -> Data
    func generateThumbnail(_ data: Data, size: CGSize) async throws -> Data
}

// MARK: - CaptionGenerating

/// AIキャプション生成プロトコル（DI・テスト用）
public protocol CaptionGenerating: Sendable {
    /// 画像から1つのキャプションを生成
    func generateCaption(for imageData: Data, classifications: [String]) async throws -> String

    /// 画像から複数のキャプション候補を生成
    func generateCaptions(for imageData: Data, count: Int) async throws -> [String]
}

// MARK: - ImageAnalysisServiceProtocol

/// 画像分析プロトコル（DI・テスト用）
public protocol ImageAnalysisServiceProtocol: Sendable {
    func classifyImage(data: Data) async throws -> [String]
    func detectText(data: Data) async throws -> [String]
    func analyzeImage(data: Data) async throws -> ImageAnalysisResult
}

// MARK: - ImageAnalysisResult

/// 画像分析結果
public struct ImageAnalysisResult: Sendable {
    public let classifications: [String]
    public let detectedTexts: [String]

    public init(classifications: [String], detectedTexts: [String]) {
        self.classifications = classifications
        self.detectedTexts = detectedTexts
    }
}
