import Foundation
import UIKit
import Photos

// MARK: - ExportService
/// 画像エクスポートサービス
/// 複数解像度でのバッチエクスポートをサポート
actor ExportService {
    // MARK: - Types

    /// エクスポート解像度
    enum ExportResolution: String, CaseIterable, Identifiable {
        case original = "オリジナル"
        case high = "高解像度 (2048px)"
        case medium = "中解像度 (1024px)"
        case low = "低解像度 (512px)"
        case thumbnail = "サムネイル (256px)"

        var id: String { rawValue }

        var maxDimension: CGFloat? {
            switch self {
            case .original: return nil
            case .high: return 2048
            case .medium: return 1024
            case .low: return 512
            case .thumbnail: return 256
            }
        }

        var description: String {
            switch self {
            case .original: return "元のサイズを維持"
            case .high: return "SNS投稿に最適"
            case .medium: return "Web表示に最適"
            case .low: return "メール添付に最適"
            case .thumbnail: return "プレビュー用"
            }
        }
    }

    /// エクスポート形式
    enum ExportFormat: String, CaseIterable, Identifiable {
        case jpeg = "JPEG"
        case png = "PNG"
        case heic = "HEIC"

        var id: String { rawValue }

        var fileExtension: String {
            switch self {
            case .jpeg: return "jpg"
            case .png: return "png"
            case .heic: return "heic"
            }
        }

        var mimeType: String {
            switch self {
            case .jpeg: return "image/jpeg"
            case .png: return "image/png"
            case .heic: return "image/heic"
            }
        }
    }

    /// エクスポート結果
    struct ExportResult {
        let resolution: ExportResolution
        let format: ExportFormat
        let data: Data
        let size: CGSize
        let fileSize: Int
    }

    // MARK: - Properties

    private let compressionQuality: CGFloat

    // MARK: - Initializer

    init(compressionQuality: CGFloat = 0.9) {
        self.compressionQuality = compressionQuality
    }

    // MARK: - Public Methods

    /// 単一解像度でエクスポート
    func export(
        image: UIImage,
        resolution: ExportResolution,
        format: ExportFormat
    ) -> ExportResult? {
        let resizedImage = resizeImage(image, maxDimension: resolution.maxDimension)

        guard let data = createData(from: resizedImage, format: format) else { return nil }

        return ExportResult(
            resolution: resolution,
            format: format,
            data: data,
            size: resizedImage.size,
            fileSize: data.count
        )
    }

    /// 複数解像度でバッチエクスポート
    func batchExport(
        image: UIImage,
        resolutions: [ExportResolution],
        format: ExportFormat
    ) -> [ExportResult] {
        var results: [ExportResult] = []

        for resolution in resolutions {
            if let result = export(image: image, resolution: resolution, format: format) {
                results.append(result)
            }
        }

        return results
    }

    /// 写真ライブラリに保存
    func saveToPhotoLibrary(image: UIImage) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                switch status {
                case .authorized, .limited:
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    } completionHandler: { success, error in
                        if success {
                            continuation.resume()
                        } else {
                            continuation.resume(throwing: error ?? ExportError.saveFailed)
                        }
                    }

                case .denied, .restricted:
                    continuation.resume(throwing: ExportError.permissionDenied)

                case .notDetermined:
                    continuation.resume(throwing: ExportError.permissionDenied)

                @unknown default:
                    continuation.resume(throwing: ExportError.unknown)
                }
            }
        }
    }

    /// ファイルに保存（Documents ディレクトリ）
    func saveToFile(
        image: UIImage,
        filename: String,
        resolution: ExportResolution,
        format: ExportFormat
    ) throws -> URL {
        guard let result = export(image: image, resolution: resolution, format: format) else {
            throw ExportError.exportFailed
        }

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("\(filename).\(format.fileExtension)")

        try result.data.write(to: fileURL)

        return fileURL
    }

    // MARK: - Private Methods

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat?) -> UIImage {
        guard let maxDimension = maxDimension else { return image }

        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height)

        // スケールが1以上なら元のサイズを維持
        if scale >= 1 { return image }

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func createData(from image: UIImage, format: ExportFormat) -> Data? {
        switch format {
        case .jpeg:
            return image.jpegData(compressionQuality: compressionQuality)

        case .png:
            return image.pngData()

        case .heic:
            // HEIC形式でエクスポート
            if let cgImage = image.cgImage {
                let data = NSMutableData()
                guard let destination = CGImageDestinationCreateWithData(
                    data,
                    "public.heic" as CFString,
                    1,
                    nil
                ) else { return nil }

                let options: [CFString: Any] = [
                    kCGImageDestinationLossyCompressionQuality: compressionQuality
                ]

                CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

                if CGImageDestinationFinalize(destination) {
                    return data as Data
                }
            }
            // HEICが使えない場合はJPEGにフォールバック
            return image.jpegData(compressionQuality: compressionQuality)
        }
    }
}

// MARK: - ExportError
enum ExportError: LocalizedError {
    case exportFailed
    case saveFailed
    case permissionDenied
    case unknown

    var errorDescription: String? {
        switch self {
        case .exportFailed:
            return "画像のエクスポートに失敗しました"
        case .saveFailed:
            return "画像の保存に失敗しました"
        case .permissionDenied:
            return "写真ライブラリへのアクセス許可が必要です"
        case .unknown:
            return "不明なエラーが発生しました"
        }
    }
}
