//
//  PhotoLibraryService.swift
//  AsaFamilyAlbum
//
//  Created on 2025/09/05
//

import Foundation
import Photos
import SwiftUI

final class PhotoLibraryService: NSObject, ObservableObject {
    static let shared = PhotoLibraryService()
    
    @Published private(set) var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var assets: [PHAsset] = []
    @Published private(set) var errorMessage: String?
    
    private let imageManager = PHCachingImageManager()
    private var allAssets: PHFetchResult<PHAsset>?
    
    override init() {
        super.init()
        checkAuthorizationStatus()
        // PHPhotoLibrary.shared().register(self) // TODO: オブザーバー機能復旧時に有効化
    }
    
    deinit {
        // PHPhotoLibrary.shared().unregisterChangeObserver(self) // TODO: オブザーバー機能復旧時に有効化
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func requestPhotoLibraryAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                DispatchQueue.main.async {
                    self?.authorizationStatus = status
                    continuation.resume(returning: status == .authorized || status == .limited)
                }
            }
        }
    }
    
    var hasPhotoLibraryAccess: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }
    
    // MARK: - Photo Loading
    
    @MainActor
    func loadPhotos() async {
        guard hasPhotoLibraryAccess else {
            errorMessage = "写真ライブラリへのアクセスが許可されていません"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: false)
            ]
            fetchOptions.includeHiddenAssets = false
            // fetchOptions.includeAllBurstPhotos = false // TODO: 正しいAPIを確認
            
            let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            allAssets = result
            
            var loadedAssets: [PHAsset] = []
            result.enumerateObjects { asset, _, _ in
                loadedAssets.append(asset)
            }
            
            assets = loadedAssets
            isLoading = false
        } catch {
            errorMessage = "写真の読み込みに失敗しました: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func loadImage(
        for asset: PHAsset,
        targetSize: CGSize = CGSize(width: 300, height: 300),
        contentMode: PHImageContentMode = .aspectFill
    ) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    func loadFullSizeImage(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            
            imageManager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .default,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    // MARK: - EXIF Data
    
    func loadExifData(for asset: PHAsset) async -> [String: Any]? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            
            imageManager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                guard let data = data,
                      let source = CGImageSourceCreateWithData(data as CFData, nil),
                      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(returning: properties)
            }
        }
    }
    
    func extractCameraInfo(from exifData: [String: Any]) -> (make: String?, model: String?, aperture: String?, shutterSpeed: String?, iso: String?) {
        let tiffData = exifData[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        let exifDict = exifData[kCGImagePropertyExifDictionary as String] as? [String: Any]
        
        let make = tiffData?[kCGImagePropertyTIFFMake as String] as? String
        let model = tiffData?[kCGImagePropertyTIFFModel as String] as? String
        
        var aperture: String?
        if let apertureValue = exifDict?[kCGImagePropertyExifFNumber as String] as? NSNumber {
            aperture = String(format: "%.1f", apertureValue.doubleValue)
        }
        
        var shutterSpeed: String?
        if let exposureTime = exifDict?[kCGImagePropertyExifExposureTime as String] as? NSNumber {
            shutterSpeed = String(format: "1/%.0f", 1.0 / exposureTime.doubleValue)
        }
        
        var iso: String?
        if let isoArray = exifDict?[kCGImagePropertyExifISOSpeedRatings as String] as? [NSNumber],
           let isoValue = isoArray.first {
            iso = "\(isoValue.intValue)"
        }
        
        return (make, model, aperture, shutterSpeed, iso)
    }
    
    // MARK: - Search and Filter
    
    @MainActor
    func searchPhotos(
        byDate startDate: Date? = nil,
        endDate: Date? = nil,
        location: String? = nil
    ) async -> [PHAsset] {
        guard hasPhotoLibraryAccess else { return [] }
        
        let fetchOptions = PHFetchOptions()
        var predicates: [NSPredicate] = []
        
        // 日付フィルター
        if let startDate = startDate {
            predicates.append(NSPredicate(format: "creationDate >= %@", startDate as NSDate))
        }
        
        if let endDate = endDate {
            predicates.append(NSPredicate(format: "creationDate <= %@", endDate as NSDate))
        }
        
        // 場所フィルター（位置情報がある写真のみ）
        if location != nil {
            predicates.append(NSPredicate(format: "location != nil"))
        }
        
        if !predicates.isEmpty {
            fetchOptions.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var filteredAssets: [PHAsset] = []
        
        result.enumerateObjects { asset, _, _ in
            filteredAssets.append(asset)
        }
        
        return filteredAssets
    }
    
    func getAssetsByDateRange() -> [String: [PHAsset]] {
        let calendar = Calendar.current
        var groupedAssets: [String: [PHAsset]] = [:]
        
        for asset in assets {
            let components = calendar.dateComponents([.year, .month], from: asset.creationDate ?? Date())
            let key = String(format: "%d年%d月", components.year ?? 0, components.month ?? 0)
            
            if groupedAssets[key] == nil {
                groupedAssets[key] = []
            }
            groupedAssets[key]?.append(asset)
        }
        
        return groupedAssets
    }
    
    // MARK: - Utility
    
    func createPhoto(from asset: PHAsset) -> Photo {
        let photo = Photo(
            assetID: asset.localIdentifier,
            createdAt: asset.creationDate ?? Date(),
            location: asset.location?.description
        )
        
        // EXIFデータを非同期で取得して更新
        Task {
            if let exifData = await loadExifData(for: asset) {
                let cameraInfo = extractCameraInfo(from: exifData)
                await MainActor.run {
                    photo.cameraMake = cameraInfo.make
                    photo.cameraModel = cameraInfo.model
                    photo.aperture = cameraInfo.aperture
                    photo.shutterSpeed = cameraInfo.shutterSpeed
                    photo.iso = cameraInfo.iso
                    photo.updateTimestamp()
                }
            }
        }
        
        return photo
    }
    
    func getAsset(for photo: Photo) -> PHAsset? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = 1
        
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [photo.assetID], options: fetchOptions)
        return result.firstObject
    }
}

// MARK: - PHPhotoLibraryChangeObserver (一時的に無効化)

// TODO: PHPhotoLibraryChangeInfo型エラー解決後に復旧
extension PhotoLibraryService { // : PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: Any) {
        // PHPhotoLibraryChangeInfoの型エラー回避のAny型使用
        guard let changeInfo = changeInstance as? NSObject else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // TODO: PHPhotoLibraryChangeInfo型エラー解決後に機能復旧
            // 写真ライブラリの変更を検出し、UIを更新する処理
            print("Photo library changed - functionality temporarily disabled")
            
            /*
            if let changes = changeInstance.changeDetails(for: allAssets) {
                self.allAssets = changes.fetchResultAfterChanges
                
                self.assets = updatedAssets
            }
            */
        }
    }
}

// MARK: - Error Types

enum PhotoLibraryError: Error, LocalizedError {
    case accessDenied
    case loadingFailed
    case assetNotFound
    case exportFailed
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "写真ライブラリへのアクセスが拒否されました"
        case .loadingFailed:
            return "写真の読み込みに失敗しました"
        case .assetNotFound:
            return "指定された写真が見つかりません"
        case .exportFailed:
            return "写真のエクスポートに失敗しました"
        }
    }
}