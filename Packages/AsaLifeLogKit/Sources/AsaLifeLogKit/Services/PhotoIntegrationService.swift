#if os(iOS)
import Foundation
import Photos

// MARK: - PhotoIntegrationService

/// Photos フレームワーク ラッパーサービス
///
/// 写真ライブラリからアセット情報の取得・サムネイル生成を提供する。
@MainActor
@Observable
public final class PhotoIntegrationService: PhotoIntegrationServiceProtocol {

    // MARK: - Init

    public init() {}

    // MARK: - PhotoIntegrationServiceProtocol

    public func requestAuthorization() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized || status == .limited
    }

    public func fetchPhotos(for date: Date) async throws -> [PhotoAssetInfo] {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            throw LifeLogError.photoAccessDenied
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "creationDate >= %@ AND creationDate < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let results = PHAsset.fetchAssets(with: .image, options: options)
        var assets: [PhotoAssetInfo] = []
        results.enumerateObjects { asset, _, _ in
            let location: PhotoLocation?
            if let loc = asset.location {
                location = PhotoLocation(
                    latitude: loc.coordinate.latitude,
                    longitude: loc.coordinate.longitude
                )
            } else {
                location = nil
            }
            assets.append(PhotoAssetInfo(
                id: asset.localIdentifier,
                createdDate: asset.creationDate,
                location: location
            ))
        }
        return assets
    }

    public func fetchThumbnail(assetIdentifier: String) async throws -> Data? {
        let results = PHAsset.fetchAssets(
            withLocalIdentifiers: [assetIdentifier],
            options: nil
        )
        guard let asset = results.firstObject else {
            throw LifeLogError.dataNotFound
        }

        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestImageDataAndOrientation(
                for: asset,
                options: options
            ) { data, _, _, _ in
                continuation.resume(returning: data)
            }
        }
    }
}
#endif
