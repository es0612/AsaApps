//
//  ImageStorageService.swift
//  AsaFamilyAlbum
//
//  Created on 2025/10/14
//

import Foundation
import UIKit

/// ローカルストレージへの画像保存・読み込みを管理するサービス
final class ImageStorageService {
    static let shared = ImageStorageService()

    // MARK: - Properties

    private let fileManager = FileManager.default
    private let photosDirectory: URL

    // 画像圧縮設定
    private let jpegCompressionQuality: CGFloat = 0.8
    private let maxImageDimension: CGFloat = 4096

    // MARK: - Initialization

    private init() {
        // Documents/Photos/ ディレクトリのパスを取得
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        photosDirectory = documentsPath.appendingPathComponent("Photos", isDirectory: true)

        // ディレクトリが存在しない場合は作成
        createPhotosDirectoryIfNeeded()
    }

    // MARK: - Directory Management

    private func createPhotosDirectoryIfNeeded() {
        guard !fileManager.fileExists(atPath: photosDirectory.path) else { return }

        do {
            try fileManager.createDirectory(
                at: photosDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            print("📁 Photos directory created: \(photosDirectory.path)")
        } catch {
            print("❌ Failed to create photos directory: \(error.localizedDescription)")
        }
    }

    // MARK: - Image Saving

    /// UIImageをローカルストレージに保存
    /// - Parameter image: 保存する画像
    /// - Returns: 保存された画像のファイルパス（相対パス）
    func saveImage(_ image: UIImage) async -> String? {
        // 大きすぎる画像はリサイズ
        let resizedImage = await resizeImageIfNeeded(image)

        // JPEG形式に変換
        guard let imageData = resizedImage.jpegData(compressionQuality: jpegCompressionQuality) else {
            print("❌ Failed to convert image to JPEG data")
            return nil
        }

        // ファイル名を生成（UUID + .jpg）
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = photosDirectory.appendingPathComponent(filename)

        do {
            // ディレクトリが存在することを確認
            createPhotosDirectoryIfNeeded()

            // ファイルに書き込み
            try imageData.write(to: fileURL)
            print("✅ Image saved: \(filename), size: \(imageData.count / 1024)KB")

            // 相対パスを返す（Photos/UUID.jpg）
            return "Photos/\(filename)"
        } catch {
            print("❌ Failed to save image: \(error.localizedDescription)")
            return nil
        }
    }

    /// 複数の画像を一括保存
    /// - Parameter images: 保存する画像の配列
    /// - Returns: 保存された画像のファイルパスの配列
    func saveImages(_ images: [UIImage]) async -> [String] {
        var paths: [String] = []

        for image in images {
            if let path = await saveImage(image) {
                paths.append(path)
            }
        }

        return paths
    }

    // MARK: - Image Loading

    /// ローカルストレージから画像を読み込み
    /// - Parameter relativePath: 相対パス（例: "Photos/UUID.jpg"）
    /// - Returns: 読み込んだUIImage、失敗時はnil
    func loadImage(from relativePath: String) async -> UIImage? {
        print("🔍 DEBUG [ImageStorageService.loadImage]: relativePath = \(relativePath)")
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(relativePath)
        print("🔍 DEBUG [ImageStorageService.loadImage]: fullPath = \(fileURL.path)")

        let fileExists = fileManager.fileExists(atPath: fileURL.path)
        print("🔍 DEBUG [ImageStorageService.loadImage]: fileExists = \(fileExists)")

        guard fileExists else {
            print("❌ Image file not found: \(relativePath)")
            return nil
        }

        do {
            let imageData = try Data(contentsOf: fileURL)
            print("🔍 DEBUG [ImageStorageService.loadImage]: imageData.count = \(imageData.count) bytes")
            guard let image = UIImage(data: imageData) else {
                print("❌ Failed to create UIImage from data: \(relativePath)")
                return nil
            }
            print("✅ DEBUG [ImageStorageService.loadImage]: Successfully loaded image, size = \(image.size)")
            return image
        } catch {
            print("❌ Failed to load image: \(error.localizedDescription)")
            return nil
        }
    }

    /// 画像を指定サイズにリサイズして読み込み
    /// - Parameters:
    ///   - relativePath: 相対パス
    ///   - size: 目標サイズ
    /// - Returns: リサイズされた画像
    func loadImage(from relativePath: String, targetSize: CGSize) async -> UIImage? {
        guard let originalImage = await loadImage(from: relativePath) else {
            return nil
        }

        return await resizeImage(originalImage, to: targetSize)
    }

    // MARK: - Image Deletion

    /// ローカルストレージから画像を削除
    /// - Parameter relativePath: 削除する画像の相対パス
    /// - Returns: 削除成功ならtrue
    func deleteImage(at relativePath: String) -> Bool {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(relativePath)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("⚠️ Image file does not exist: \(relativePath)")
            return false
        }

        do {
            try fileManager.removeItem(at: fileURL)
            print("🗑️ Image deleted: \(relativePath)")
            return true
        } catch {
            print("❌ Failed to delete image: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Utility

    /// 画像が最大サイズを超えている場合にリサイズ
    private func resizeImageIfNeeded(_ image: UIImage) async -> UIImage {
        let maxDimension = max(image.size.width, image.size.height)

        guard maxDimension > maxImageDimension else {
            return image
        }

        let scale = maxImageDimension / maxDimension
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        return await resizeImage(image, to: newSize)
    }

    /// 画像を指定サイズにリサイズ
    private func resizeImage(_ image: UIImage, to targetSize: CGSize) async -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    /// ストレージ使用量を取得
    func getStorageInfo() -> (totalSize: Int64, fileCount: Int) {
        var totalSize: Int64 = 0
        var fileCount = 0

        guard let enumerator = fileManager.enumerator(
            at: photosDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return (0, 0)
        }

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else {
                continue
            }

            totalSize += Int64(fileSize)
            fileCount += 1
        }

        return (totalSize, fileCount)
    }

    /// ストレージ使用量を人間が読める形式で取得
    func getStorageInfoFormatted() -> String {
        let (totalSize, fileCount) = getStorageInfo()
        let sizeInMB = Double(totalSize) / 1024.0 / 1024.0
        return String(format: "%.2f MB (%d files)", sizeInMB, fileCount)
    }
}

// MARK: - Error Types

enum ImageStorageError: Error, LocalizedError {
    case directoryCreationFailed
    case imageConversionFailed
    case saveFailed
    case loadFailed
    case deleteFailed
    case insufficientStorage

    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed:
            return "画像保存ディレクトリの作成に失敗しました"
        case .imageConversionFailed:
            return "画像の変換に失敗しました"
        case .saveFailed:
            return "画像の保存に失敗しました"
        case .loadFailed:
            return "画像の読み込みに失敗しました"
        case .deleteFailed:
            return "画像の削除に失敗しました"
        case .insufficientStorage:
            return "ストレージ容量が不足しています"
        }
    }
}
