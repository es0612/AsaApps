#if os(iOS)
import Foundation
import UIKit
import Vision

// MARK: - VisionCaptionService

/// Vision分類結果からキャプションを生成するサービス
public final class VisionCaptionService: CaptionGenerating {
    // MARK: - Init

    public init() {}

    // MARK: - CaptionGenerating

    /// 画像と分類結果から1つのキャプションを生成
    public func generateCaption(for imageData: Data, classifications: [String]) async throws -> String {
        let captions = try await generateCaptions(for: imageData, count: 1)
        guard let caption = captions.first else {
            throw PhotoStoryError.captionGenerationFailed
        }
        return caption
    }

    /// 画像と分類結果から複数のキャプション候補を生成
    public func generateCaptions(for imageData: Data, count: Int) async throws -> [String] {
        // Vision Frameworkで画像を分析
        guard let cgImage = UIImage(data: imageData)?.cgImage else {
            throw PhotoStoryError.captionGenerationFailed
        }

        let classifications = try await classifyImage(cgImage: cgImage)
        return generateCaptionsFromLabels(classifications, count: count)
    }

    // MARK: - Private Methods

    private func classifyImage(cgImage: CGImage) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let results = (request.results as? [VNClassificationObservation]) ?? []
                let labels = results
                    .filter { $0.confidence > 0.3 }
                    .prefix(5)
                    .map(\.identifier)
                continuation.resume(returning: Array(labels))
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: PhotoStoryError.captionGenerationFailed)
            }
        }
    }

    private func generateCaptionsFromLabels(_ labels: [String], count: Int) -> [String] {
        let labelMap: [String: String] = [
            "outdoor": "屋外での素敵なひととき",
            "indoor": "室内のあたたかな時間",
            "people": "みんなの笑顔が輝く瞬間",
            "food": "美味しい思い出",
            "animal": "かわいい動物との出会い",
            "nature": "自然の美しさに包まれて",
            "sky": "空が広がる風景",
            "water": "水辺の心地よい時間",
            "building": "街並みの記録",
            "plant": "緑に囲まれた穏やかな日",
            "flower": "花が彩る特別な日",
            "beach": "海辺の楽しい思い出",
            "mountain": "山の壮大な景色",
            "sunset": "夕焼けの美しい一瞬",
            "night": "夜の静かなひととき",
        ]

        var captions: [String] = []

        for label in labels.prefix(count) {
            if let caption = labelMap[label] {
                captions.append(caption)
            } else {
                captions.append("大切な思い出のワンシーン")
            }
        }

        // 候補が足りない場合はデフォルトを追加
        while captions.count < count {
            captions.append("かけがえのない一瞬")
        }

        return captions
    }
}

// MARK: - CaptionServiceFactory

/// キャプションサービスのファクトリー
/// 将来的にFoundation Models対応時に切替可能
public enum CaptionServiceFactory {
    public static func create() -> any CaptionGenerating {
        // iOS 26以降でFoundation Models APIが利用可能になった場合:
        // if #available(iOS 26, *) {
        //     return FoundationModelCaptionService()
        // }
        return VisionCaptionService()
    }
}

// MARK: - Foundation Models版（iOS 26以降で利用可能）

// @available(iOS 26, *)
// public final class FoundationModelCaptionService: CaptionGenerating {
//     public init() {}
//
//     public func generateCaption(for imageData: Data, classifications: [String]) async throws -> String {
//         // Foundation Models APIを使ったキャプション生成
//         // let session = LanguageModelSession()
//         // let response = try await session.respond(to: "この画像を説明してください")
//         // return response.content
//         fatalError("iOS 26+ が必要です")
//     }
//
//     public func generateCaptions(for imageData: Data, count: Int) async throws -> [String] {
//         fatalError("iOS 26+ が必要です")
//     }
// }
#endif
