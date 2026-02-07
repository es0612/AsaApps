#if os(iOS)
import Foundation
import UIKit
import Vision

// MARK: - ImageAnalysisService

/// Vision Frameworkを使った画像分析サービス
public actor ImageAnalysisService: ImageAnalysisServiceProtocol {
    // MARK: - Init

    public init() {}

    // MARK: - Public Methods

    /// 画像を分類（VNClassifyImageRequest）
    public func classifyImage(data: Data) async throws -> [String] {
        guard let cgImage = UIImage(data: data)?.cgImage else {
            throw PhotoStoryError.visionAnalysisFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
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
                continuation.resume(throwing: PhotoStoryError.visionAnalysisFailed)
            }
        }
    }

    /// テキスト検出（VNRecognizeTextRequest）
    public func detectText(data: Data) async throws -> [String] {
        guard let cgImage = UIImage(data: data)?.cgImage else {
            throw PhotoStoryError.visionAnalysisFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let results = (request.results as? [VNRecognizedTextObservation]) ?? []
                let texts = results.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                continuation.resume(returning: texts)
            }
            request.recognitionLanguages = ["ja", "en"]
            request.recognitionLevel = .accurate

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: PhotoStoryError.visionAnalysisFailed)
            }
        }
    }

    /// 画像を総合分析（分類 + テキスト検出）
    public func analyzeImage(data: Data) async throws -> ImageAnalysisResult {
        async let classifications = classifyImage(data: data)
        async let texts = detectText(data: data)

        return try await ImageAnalysisResult(
            classifications: classifications,
            detectedTexts: texts
        )
    }
}
#endif
