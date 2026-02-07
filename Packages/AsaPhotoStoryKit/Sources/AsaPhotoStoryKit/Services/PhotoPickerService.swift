#if os(iOS)
import Foundation
import PhotosUI
import SwiftUI

// MARK: - PhotoPickerService

/// PhotosPickerから画像を読み込むサービス
public actor PhotoPickerService {
    // MARK: - Init

    public init() {}

    // MARK: - Public Methods

    /// 複数のPhotosPickerItemから画像データを読み込み
    public func loadImages(from results: [PhotosPickerItem]) async throws -> [Data] {
        var images: [Data] = []

        for result in results {
            let data = try await loadImage(from: result)
            images.append(data)
        }

        return images
    }

    /// 単一のPhotosPickerItemから画像データを読み込み
    public func loadImage(from result: PhotosPickerItem) async throws -> Data {
        guard let data = try await result.loadTransferable(type: Data.self) else {
            throw PhotoStoryError.photoPickerFailed
        }
        return data
    }
}
#endif
