#if os(iOS)
import AVFoundation
import CoreGraphics
import Foundation
import UIKit

// MARK: - SlideshowExportService

/// スライドショーのエクスポート（動画/画像/PDF）を管理するサービス
public actor SlideshowExportService {
    // MARK: - Init

    public init() {}

    // MARK: - 動画エクスポート

    /// ストーリーを動画としてエクスポート
    public func exportAsVideo(
        pages: [StoryPage],
        settings: ExportSettings,
        progress: @Sendable (Double) -> Void
    ) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("story_\(UUID().uuidString).mp4")

        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            throw PhotoStoryError.exportFailed("動画ライターの作成に失敗")
        }

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: settings.resolution.width,
            AVVideoHeightKey: settings.resolution.height,
        ]

        let writerInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: videoSettings
        )

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: settings.resolution.width,
                kCVPixelBufferHeightKey as String: settings.resolution.height,
            ]
        )

        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        let fps: Int32 = 30
        var frameIndex: Int64 = 0
        let totalPages = pages.count

        for (pageIndex, page) in pages.enumerated() {
            let frameDuration = Int64(page.duration * Double(fps))

            // ページの背景画像 or プレースホルダーを描画
            let image = createPageImage(
                page: page,
                size: CGSize(
                    width: CGFloat(settings.resolution.width),
                    height: CGFloat(settings.resolution.height)
                )
            )

            guard let pixelBuffer = createPixelBuffer(
                from: image,
                width: settings.resolution.width,
                height: settings.resolution.height
            ) else {
                continue
            }

            for _ in 0 ..< frameDuration {
                while !writerInput.isReadyForMoreMediaData {
                    try await Task.sleep(nanoseconds: 10_000_000)
                }

                let presentationTime = CMTime(value: frameIndex, timescale: fps)
                adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                frameIndex += 1
            }

            progress(Double(pageIndex + 1) / Double(totalPages))
        }

        writerInput.markAsFinished()
        await writer.finishWriting()

        if writer.status == .failed {
            throw PhotoStoryError.exportFailed(writer.error?.localizedDescription ?? "不明なエラー")
        }

        return outputURL
    }

    // MARK: - 画像エクスポート

    /// 各ページを画像としてエクスポート
    public func exportAsImages(
        pages: [StoryPage],
        settings: ExportSettings
    ) async throws -> [Data] {
        var images: [Data] = []
        let size = CGSize(
            width: CGFloat(settings.resolution.width),
            height: CGFloat(settings.resolution.height)
        )

        for page in pages {
            let image = createPageImage(page: page, size: size)
            guard let data = image.pngData() else {
                throw PhotoStoryError.exportFailed("画像データの生成に失敗")
            }
            images.append(data)
        }

        return images
    }

    // MARK: - PDFエクスポート

    /// ストーリーをPDFとしてエクスポート
    public func exportAsPDF(
        pages: [StoryPage],
        settings: ExportSettings
    ) async throws -> Data {
        let pageSize = CGRect(
            x: 0,
            y: 0,
            width: CGFloat(settings.resolution.width),
            height: CGFloat(settings.resolution.height)
        )

        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)

        let data = renderer.pdfData { context in
            for page in pages {
                context.beginPage()
                let image = createPageImage(
                    page: page,
                    size: pageSize.size
                )
                image.draw(in: pageSize)
            }
        }

        return data
    }

    // MARK: - Private Methods

    private func createPageImage(page: StoryPage, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // 背景色を描画
            if let hex = page.backgroundColorHex,
               let color = UIColor(hexString: hex) {
                color.setFill()
            } else {
                UIColor.white.setFill()
            }
            context.fill(CGRect(origin: .zero, size: size))

            // 背景画像を描画
            if let imageData = page.backgroundImageData,
               let bgImage = UIImage(data: imageData) {
                bgImage.draw(in: CGRect(origin: .zero, size: size))
            }

            // 各要素を描画
            for element in page.sortedElements {
                drawElement(element, in: context, canvasSize: size)
            }
        }
    }

    private func drawElement(
        _ element: StoryElement,
        in context: UIGraphicsImageRendererContext,
        canvasSize: CGSize
    ) {
        let rect = CGRect(
            x: element.positionX * canvasSize.width - (element.width * canvasSize.width / 2),
            y: element.positionY * canvasSize.height - (element.height * canvasSize.height / 2),
            width: element.width * canvasSize.width,
            height: element.height * canvasSize.height
        )

        let cgContext = context.cgContext
        cgContext.saveGState()
        cgContext.setAlpha(element.opacity)

        // 回転の適用
        if element.rotation != 0 {
            let center = CGPoint(x: rect.midX, y: rect.midY)
            cgContext.translateBy(x: center.x, y: center.y)
            cgContext.rotate(by: element.rotation)
            cgContext.translateBy(x: -center.x, y: -center.y)
        }

        switch element.elementType {
        case .photo:
            if let imageData = element.imageData,
               let image = UIImage(data: imageData) {
                image.draw(in: rect)
            }

        case .text:
            if let text = element.text {
                let fontSize = element.fontSize ?? 24
                let fontName = element.fontName ?? "HiraginoSans-W6"
                let font = UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
                let color: UIColor
                if let hex = element.textColorHex {
                    color = UIColor(hexString: hex) ?? .black
                } else {
                    color = .black
                }

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                ]
                (text as NSString).draw(in: rect, withAttributes: attributes)
            }

        case .sticker:
            if let stickerName = element.stickerName {
                let config = UIImage.SymbolConfiguration(pointSize: rect.width * 0.8)
                if let symbolImage = UIImage(systemName: stickerName, withConfiguration: config) {
                    symbolImage.draw(in: rect)
                }
            }

        case .drawing:
            // PencilKitのDrawingはPKDrawing.image()で描画
            break
        }

        cgContext.restoreGState()
    }

    private func createPixelBuffer(from image: UIImage, width: Int, height: Int) -> CVPixelBuffer? {
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attrs as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let cgContext = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return nil }

        guard let cgImage = image.cgImage else { return nil }
        cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return buffer
    }
}

// MARK: - UIColor HEX Extension

private extension UIColor {
    convenience init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        hex = hex.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&rgb) else { return nil }

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
#endif
