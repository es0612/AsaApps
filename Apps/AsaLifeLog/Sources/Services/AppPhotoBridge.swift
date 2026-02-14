import Foundation
import Photos
import AsaLifeLogKit

// MARK: - AppPhotoBridge

/// Photos フレームワークと AsaLifeLogKit の橋渡しサービス
@MainActor
@Observable
final class AppPhotoBridge: PhotoIntegrationServiceProtocol {

    func requestAuthorization() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized || status == .limited
    }

    func fetchPhotos(for date: Date) async throws -> [PhotoAssetInfo] {
        let calendar = Calendar.current
        guard let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date),
              let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
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

    func fetchThumbnail(assetIdentifier: String) async throws -> Data? {
        let results = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        guard let asset = results.firstObject else { return nil }

        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isSynchronous = false
            options.resizeMode = .fast

            PHImageManager.default().requestImageDataAndOrientation(
                for: asset,
                options: options
            ) { data, _, _, _ in
                continuation.resume(returning: data)
            }
        }
    }
}
