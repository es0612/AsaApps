//
//  DataPersistenceServiceTests.swift
//  AsaFamilyAlbumTests
//
//  Created on 2025/09/05
//

import Testing
import Foundation
import SwiftData
@testable import AsaFamilyAlbum

struct DataPersistenceServiceTests {
    
    @Test("DataPersistenceService Shared Instance テスト")
    func testDataPersistenceServiceSharedInstance() async throws {
        // Act
        let service = DataPersistenceService.shared
        
        // Assert
        #expect(service != nil)
        #expect(DataPersistenceService.shared === DataPersistenceService.shared) // 同じインスタンス
    }
    
    @Test("DataPersistenceService初期化テスト")
    func testDataPersistenceServiceInitialization() async throws {
        // Act
        let service = DataPersistenceService()
        
        // Assert
        #expect(service.isLoading == false)
        #expect(service.errorMessage == nil)
    }
    
    @Test("FamilyAlbumStatistics構造体テスト")
    func testFamilyAlbumStatistics() async throws {
        // Arrange & Act
        let stats = FamilyAlbumStatistics(
            totalAlbums: 10,
            totalPhotos: 100,
            favoritePhotos: 25,
            familyMembers: 5,
            totalComments: 50
        )
        
        // Assert
        #expect(stats.totalAlbums == 10)
        #expect(stats.totalPhotos == 100)
        #expect(stats.favoritePhotos == 25)
        #expect(stats.familyMembers == 5)
        #expect(stats.totalComments == 50)
        
        // 計算プロパティのテスト
        #expect(stats.favoritePercentage == 25.0) // 25/100 * 100 = 25%
        #expect(stats.averagePhotosPerAlbum == 10.0) // 100/10 = 10
    }
    
    @Test("FamilyAlbumStatistics favoritePercentage - 写真数0の場合テスト")
    func testFamilyAlbumStatisticsFavoritePercentageZeroPhotos() async throws {
        // Arrange & Act
        let stats = FamilyAlbumStatistics(
            totalAlbums: 5,
            totalPhotos: 0,
            favoritePhotos: 0,
            familyMembers: 3,
            totalComments: 0
        )
        
        // Assert
        #expect(stats.favoritePercentage == 0.0)
    }
    
    @Test("FamilyAlbumStatistics averagePhotosPerAlbum - アルバム数0の場合テスト")
    func testFamilyAlbumStatisticsAveragePhotosPerAlbumZeroAlbums() async throws {
        // Arrange & Act
        let stats = FamilyAlbumStatistics(
            totalAlbums: 0,
            totalPhotos: 100,
            favoritePhotos: 25,
            familyMembers: 5,
            totalComments: 50
        )
        
        // Assert
        #expect(stats.averagePhotosPerAlbum == 0.0)
    }
    
    @Test("AlbumExportData構造体テスト")
    func testAlbumExportData() async throws {
        // Arrange
        let album = Album(name: "テストアルバム")
        let photo = Photo(assetIdentifier: "test-asset")
        let comment = Comment(text: "テストコメント", author: "太郎")
        let photoExportData = PhotoExportData(photo: photo, comments: [comment])
        let exportDate = Date()
        
        // Act
        let exportData = AlbumExportData(
            album: album,
            photos: [photoExportData],
            exportDate: exportDate
        )
        
        // Assert
        #expect(exportData.album.name == "テストアルバム")
        #expect(exportData.photos.count == 1)
        #expect(exportData.photos.first?.photo.assetIdentifier == "test-asset")
        #expect(exportData.photos.first?.comments.count == 1)
        #expect(exportData.exportDate == exportDate)
    }
    
    @Test("PhotoExportData構造体テスト")
    func testPhotoExportData() async throws {
        // Arrange
        let photo = Photo(assetIdentifier: "test-asset", title: "テスト写真")
        let comment1 = Comment(text: "コメント1", author: "太郎")
        let comment2 = Comment(text: "コメント2", author: "花子")
        
        // Act
        let exportData = PhotoExportData(photo: photo, comments: [comment1, comment2])
        
        // Assert
        #expect(exportData.photo.title == "テスト写真")
        #expect(exportData.comments.count == 2)
        #expect(exportData.comments.first?.author == "太郎")
        #expect(exportData.comments.last?.author == "花子")
    }
    
    @Test("DataPersistenceError ErrorDescription テスト")
    func testDataPersistenceErrorDescriptions() async throws {
        // Act & Assert
        #expect(DataPersistenceError.contextNotAvailable.errorDescription == "データベースコンテキストが利用できません")
        #expect(DataPersistenceError.saveFailed.errorDescription == "データの保存に失敗しました")
        #expect(DataPersistenceError.fetchFailed.errorDescription == "データの取得に失敗しました")
        #expect(DataPersistenceError.deleteFailed.errorDescription == "データの削除に失敗しました")
        #expect(DataPersistenceError.exportFailed.errorDescription == "データのエクスポートに失敗しました")
    }
    
    @Test("DataPersistenceError LocalizedError準拠テスト")
    func testDataPersistenceErrorLocalizedErrorConformance() async throws {
        // Arrange
        let error: Error = DataPersistenceError.contextNotAvailable
        
        // Act & Assert
        #expect(error.localizedDescription == "データベースコンテキストが利用できません")
    }
    
    @Test("FamilyAlbumStatistics小数点計算テスト")
    func testFamilyAlbumStatisticsDecimalCalculations() async throws {
        // Arrange & Act
        let stats = FamilyAlbumStatistics(
            totalAlbums: 3,
            totalPhotos: 7,
            favoritePhotos: 2,
            familyMembers: 4,
            totalComments: 15
        )
        
        // Assert
        #expect(abs(stats.favoritePercentage - 28.571428571428573) < 0.0001) // 2/7 * 100 ≈ 28.57%
        #expect(abs(stats.averagePhotosPerAlbum - 2.3333333333333335) < 0.0001) // 7/3 ≈ 2.33
    }
    
    @Test("DataPersistenceService インスタンスメソッドテスト")
    func testDataPersistenceServiceInstanceMethods() async throws {
        // Arrange
        let service = DataPersistenceService()
        
        // Act & Assert - 初期状態の確認
        #expect(service.isLoading == false)
        #expect(service.errorMessage == nil)
        
        // setModelContextメソッドのテスト（実際のModelContextが必要）
        // 実際のテストでは、テスト用のModelContextを作成してテスト
    }
    
    @Test("Statistics複雑な計算シナリオテスト")
    func testStatisticsComplexCalculationScenarios() async throws {
        // Arrange & Act - 全てが0の場合
        let emptyStats = FamilyAlbumStatistics(
            totalAlbums: 0,
            totalPhotos: 0,
            favoritePhotos: 0,
            familyMembers: 0,
            totalComments: 0
        )
        
        // Assert
        #expect(emptyStats.favoritePercentage == 0.0)
        #expect(emptyStats.averagePhotosPerAlbum == 0.0)
        
        // Arrange & Act - 極端な値の場合
        let extremeStats = FamilyAlbumStatistics(
            totalAlbums: 1,
            totalPhotos: 10000,
            favoritePhotos: 10000,
            familyMembers: 100,
            totalComments: 50000
        )
        
        // Assert
        #expect(extremeStats.favoritePercentage == 100.0)
        #expect(extremeStats.averagePhotosPerAlbum == 10000.0)
    }
}