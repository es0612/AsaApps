//
//  VisionService.swift
//  AsaRecipeAI
//
//  Visionフレームワークを使用した画像分類サービス
//  食材の画像認識を担当
//

import Foundation
import Vision
import UIKit

// MARK: - VisionService

/// Vision フレームワークを使用した画像分類サービス
@MainActor
final class VisionService: Sendable {
    // MARK: - Properties

    /// 最小信頼度閾値
    private let minimumConfidence: Float = 0.3

    /// 最大結果数
    private let maxResults: Int = 15

    // MARK: - Public Methods

    /// 画像を分類し、識別子のリストを返す
    /// - Parameter image: 分類する画像
    /// - Returns: 識別子と信頼度のタプルリスト
    func classifyImage(_ image: UIImage) async throws -> [(identifier: String, confidence: Float)] {
        // シミュレータでは CoreSceneUnderstanding の CoreML モデル（Espresso）が初期化できず、
        // VNClassifyImageRequest 実行時に CSU exception でプロセスクラッシュするため回避する。
        // 実機（Apple Intelligence 対応端末）では従来通り動作する。
        #if targetEnvironment(simulator)
        return []
        #else
        guard let cgImage = image.cgImage else {
            throw VisionError.imageConversionFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error {
                    continuation.resume(throwing: VisionError.classificationFailed(error))
                    return
                }

                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: VisionError.noResults)
                    return
                }

                let filteredResults = results
                    .filter { $0.confidence >= self.minimumConfidence }
                    .prefix(self.maxResults)
                    .map { (identifier: $0.identifier, confidence: $0.confidence) }

                continuation.resume(returning: Array(filteredResults))
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: VisionError.requestFailed(error))
            }
        }
        #endif
    }

    /// 画像から食品関連のラベルを抽出
    /// - Parameter image: 分析する画像
    /// - Returns: 食品関連の識別子リスト
    func extractFoodLabels(_ image: UIImage) async throws -> [String] {
        let results = try await classifyImage(image)

        // 食品関連のキーワードでフィルタリング
        let foodKeywords = [
            "food", "vegetable", "fruit", "meat", "fish", "seafood",
            "dairy", "egg", "bread", "rice", "noodle", "pasta",
            "sauce", "spice", "herb", "drink", "beverage",
            "carrot", "onion", "potato", "tomato", "lettuce",
            "chicken", "beef", "pork", "salmon", "tuna",
            "apple", "banana", "orange", "lemon", "grape"
        ]

        let foodLabels = results.filter { result in
            let lowercased = result.identifier.lowercased()
            return foodKeywords.contains { keyword in
                lowercased.contains(keyword)
            }
        }

        // 食品キーワードでフィルタできなかった場合は上位結果を返す
        if foodLabels.isEmpty {
            return results.prefix(10).map { $0.identifier }
        }

        return foodLabels.map { $0.identifier }
    }

    /// 画像のサムネイルを生成
    /// - Parameters:
    ///   - image: 元画像
    ///   - size: サムネイルサイズ
    /// - Returns: サムネイル画像データ
    func generateThumbnail(_ image: UIImage, size: CGSize = CGSize(width: 200, height: 200)) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return thumbnail.jpegData(compressionQuality: 0.7)
    }
}

// MARK: - VisionError

/// Vision処理のエラー
enum VisionError: Error, LocalizedError {
    case imageConversionFailed
    case classificationFailed(Error)
    case requestFailed(Error)
    case noResults

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "画像の変換に失敗しました"
        case .classificationFailed(let error):
            return "画像分類に失敗しました: \(error.localizedDescription)"
        case .requestFailed(let error):
            return "リクエストに失敗しました: \(error.localizedDescription)"
        case .noResults:
            return "分類結果がありませんでした"
        }
    }
}
