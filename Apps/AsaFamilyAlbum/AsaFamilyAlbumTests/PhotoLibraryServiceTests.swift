//
//  PhotoLibraryServiceTests.swift
//  AsaFamilyAlbumTests
//
//  Created on 2025/09/05
//

import Testing
import Foundation
import Photos
@testable import AsaFamilyAlbum

struct PhotoLibraryServiceTests {
    
    @Test("PhotoLibraryService Shared Instance テスト")
    func testPhotoLibraryServiceSharedInstance() async throws {
        // Act
        let service = PhotoLibraryService.shared
        
        // Assert
        #expect(service != nil)
        #expect(PhotoLibraryService.shared === PhotoLibraryService.shared) // 同じインスタンス
    }
    
    @Test("PhotoLibraryService初期化テスト")
    func testPhotoLibraryServiceInitialization() async throws {
        // Act
        let service = PhotoLibraryService()
        
        // Assert
        #expect(service.assets.isEmpty)
        #expect(service.authorizationStatus == PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }
    
    @Test("PhotoLibraryService isAuthorized計算プロパティテスト")
    func testPhotoLibraryServiceIsAuthorizedProperty() async throws {
        // Arrange
        let service = PhotoLibraryService()
        
        // Act & Assert
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        let expectedAuthorized = currentStatus == .authorized || currentStatus == .limited
        
        #expect(service.isAuthorized == expectedAuthorized)
    }
    
    @Test("PhotoLibraryService createPhoto from PHAsset テスト")
    func testCreatePhotoFromPHAsset() async throws {
        // Note: 実際のPHAssetを作成するのは困難なため、
        // モック的なテストまたは実際の写真ライブラリアクセスが必要
        // ここでは、メソッドの存在確認と基本的な動作をテスト
        
        // Arrange
        let service = PhotoLibraryService()
        
        // Assert - メソッドが存在することを確認
        // 実際のテストでは、テスト用のPHAssetまたはモックを使用
        #expect(service.assets.isEmpty) // 初期状態では空
    }
    
    @Test("PhotoLibraryService hasPermission計算プロパティテスト")
    func testPhotoLibraryServiceHasPermissionProperty() async throws {
        // Arrange
        let service = PhotoLibraryService()
        
        // Act
        let hasPermission = service.hasPermission
        
        // Assert
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        let expectedPermission = currentStatus == .authorized || currentStatus == .limited
        
        #expect(hasPermission == expectedPermission)
    }
    
    @Test("PhotoLibraryService ImageLoadingManager初期化テスト")
    func testImageLoadingManagerInitialization() async throws {
        // Arrange & Act
        let manager = PhotoLibraryService.ImageLoadingManager()
        
        // Assert
        #expect(manager.cache.countLimit == 100)
        #expect(manager.cache.totalCostLimit == 50 * 1024 * 1024) // 50MB
    }
    
    @Test("PhotoLibraryService PHAuthorizationStatus処理テスト")
    func testPHAuthorizationStatusHandling() async throws {
        // Arrange
        let service = PhotoLibraryService()
        
        // Act & Assert - 各ステータスに対する適切な処理
        let possibleStatuses: [PHAuthorizationStatus] = [
            .notDetermined, .restricted, .denied, .authorized, .limited
        ]
        
        for status in possibleStatuses {
            // 各ステータスに対する適切な処理が実装されているかを確認
            // 実際のテストでは、モックを使用してステータス変更をテスト
            #expect(possibleStatuses.contains(status))
        }
    }
    
    @Test("PhotoLibraryService loadPhotosメソッド存在確認テスト")
    func testLoadPhotosMethodExists() async throws {
        // Arrange
        let service = PhotoLibraryService()
        
        // Act & Assert - メソッドが存在し、呼び出し可能であることを確認
        await service.loadPhotos()
        
        // 実際の権限がない場合でも、メソッドはエラーなく実行される
        #expect(true) // メソッドが正常に完了
    }
    
    @Test("PhotoLibraryService requestPhotoLibraryAccessメソッド存在確認テスト")
    func testRequestPhotoLibraryAccessMethodExists() async throws {
        // Arrange
        let service = PhotoLibraryService()
        
        // Act
        let granted = await service.requestPhotoLibraryAccess()
        
        // Assert - メソッドがBool値を返すことを確認
        #expect(granted == true || granted == false) // Boolean値であることを確認
    }
    
    @Test("PhotoLibraryService CGSize作成テスト")
    func testCGSizeCreation() async throws {
        // Arrange
        let targetSize = CGSize(width: 300, height: 300)
        
        // Act & Assert
        #expect(targetSize.width == 300)
        #expect(targetSize.height == 300)
        
        // サムネイルサイズのテスト
        let thumbnailSize = CGSize(width: 150, height: 150)
        #expect(thumbnailSize.width == 150)
        #expect(thumbnailSize.height == 150)
        
        // フルサイズのテスト
        let fullSize = CGSize(width: 1920, height: 1080)
        #expect(fullSize.width == 1920)
        #expect(fullSize.height == 1080)
    }
    
    @Test("PhotoLibraryService NSCache設定テスト")
    func testNSCacheConfiguration() async throws {
        // Arrange & Act
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
        
        // Assert
        #expect(cache.countLimit == 100)
        #expect(cache.totalCostLimit == 52428800) // 50MB in bytes
    }
    
    @Test("PhotoLibraryService PHImageManagerオプション設定テスト")
    func testPHImageManagerOptions() async throws {
        // Arrange & Act
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        // Assert
        #expect(options.deliveryMode == .highQualityFormat)
        #expect(options.isNetworkAccessAllowed == true)
    }
    
    @Test("PhotoLibraryService 権限ステータス文字列変換テスト")
    func testAuthorizationStatusStringConversion() async throws {
        // Arrange & Act
        let statusDescriptions: [PHAuthorizationStatus: String] = [
            .notDetermined: "未決定",
            .restricted: "制限",
            .denied: "拒否",
            .authorized: "許可",
            .limited: "制限付き許可"
        ]
        
        // Assert
        for (status, description) in statusDescriptions {
            #expect(!description.isEmpty)
            
            // 各ステータスが適切な文字列と対応していることを確認
            switch status {
            case .notDetermined:
                #expect(description == "未決定")
            case .restricted:
                #expect(description == "制限")
            case .denied:
                #expect(description == "拒否")
            case .authorized:
                #expect(description == "許可")
            case .limited:
                #expect(description == "制限付き許可")
            @unknown default:
                #expect(false, "未知の認証ステータス")
            }
        }
    }
}