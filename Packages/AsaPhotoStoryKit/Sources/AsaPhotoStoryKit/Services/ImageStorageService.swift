#if os(iOS)
import Foundation
import UIKit

// MARK: - ImageStorageService

/// 画像ファイルの保存・読み込み・リサイズを管理するサービス
public actor ImageStorageService: ImageStorageServiceProtocol {
    // MARK: - Properties

    private let fileManager: FileManager
    private let baseDirectory: URL

    // MARK: - Init

    public init(directoryName: String = "PhotoStoryImages") {
        self.fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.baseDirectory = documentsURL.appendingPathComponent(directoryName)

        // ディレクトリが存在しない場合は作成
        if !fileManager.fileExists(atPath: baseDirectory.path) {
            try? fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Public Methods

    /// 画像データをファイルに保存
    public func saveImage(_ data: Data, filename: String) async throws -> URL {
        let fileURL = baseDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            throw PhotoStoryError.imageSaveFailed
        }
    }

    /// ファイルから画像データを読み込み
    public func loadImage(filename: String) async throws -> Data {
        let fileURL = baseDirectory.appendingPathComponent(filename)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw PhotoStoryError.imageLoadFailed
        }
        do {
            return try Data(contentsOf: fileURL)
        } catch {
            throw PhotoStoryError.imageLoadFailed
        }
    }

    /// 画像ファイルを削除
    public func deleteImage(filename: String) async throws {
        let fileURL = baseDirectory.appendingPathComponent(filename)
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            throw PhotoStoryError.imageSaveFailed
        }
    }

    /// 画像をリサイズ（最大辺を指定）
    public func resizeImage(_ data: Data, maxDimension: CGFloat) async throws -> Data {
        guard let image = UIImage(data: data) else {
            throw PhotoStoryError.imageResizeFailed
        }

        let originalSize = image.size
        let scale: CGFloat

        if originalSize.width > originalSize.height {
            scale = maxDimension / originalSize.width
        } else {
            scale = maxDimension / originalSize.height
        }

        // 既に十分小さい場合はそのまま返す
        guard scale < 1.0 else { return data }

        let newSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        guard let resizedData = resizedImage.jpegData(compressionQuality: 0.85) else {
            throw PhotoStoryError.imageResizeFailed
        }

        return resizedData
    }

    /// サムネイル画像を生成
    public func generateThumbnail(_ data: Data, size: CGSize) async throws -> Data {
        guard let image = UIImage(data: data) else {
            throw PhotoStoryError.imageResizeFailed
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }

        guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) else {
            throw PhotoStoryError.imageResizeFailed
        }

        return thumbnailData
    }
}
#endif
