//
//  AlbumModelTests.swift
//  AsaFamilyAlbumTests
//
//  Created on 2025/09/05
//

import Testing
import Foundation
import SwiftData
@testable import AsaFamilyAlbum

struct AlbumModelTests {
    
    @Test("Album初期化テスト")
    func testAlbumInitialization() async throws {
        // Arrange & Act
        let album = Album(
            name: "テストアルバム",
            albumDescription: "テスト用の説明",
            tags: ["テスト", "家族"]
        )
        
        // Assert
        #expect(album.name == "テストアルバム")
        #expect(album.albumDescription == "テスト用の説明")
        #expect(album.tags.contains("テスト"))
        #expect(album.tags.contains("家族"))
        #expect(album.isArchived == false)
        #expect(album.photos.isEmpty)
    }
    
    @Test("Album photoCount計算テスト")
    func testAlbumPhotoCount() async throws {
        // Arrange
        let album = Album(name: "テストアルバム")
        
        // Act & Assert
        #expect(album.photoCount == 0)
        
        // SwiftDataのリレーション機能を使ってphotoを追加する場合
        // 実際のテストでは、ModelContainerが必要
    }
    
    @Test("Album updateTimestampテスト")
    func testAlbumUpdateTimestamp() async throws {
        // Arrange
        let album = Album(name: "テストアルバム")
        let originalTimestamp = album.updatedAt
        
        // Act - 少し待機してからタイムスタンプ更新
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01秒
        album.updateTimestamp()
        
        // Assert
        #expect(album.updatedAt > originalTimestamp)
    }
    
    @Test("Album addTagテスト")
    func testAlbumAddTag() async throws {
        // Arrange
        let album = Album(name: "テストアルバム")
        
        // Act
        album.addTag("新しいタグ")
        
        // Assert
        #expect(album.tags.contains("新しいタグ"))
        
        // 同じタグを追加しても重複しない
        album.addTag("新しいタグ")
        let tagCount = album.tags.filter { $0 == "新しいタグ" }.count
        #expect(tagCount == 1)
    }
    
    @Test("Album removeTagテスト")
    func testAlbumRemoveTag() async throws {
        // Arrange
        let album = Album(name: "テストアルバム", tags: ["タグ1", "タグ2"])
        
        // Act
        album.removeTag("タグ1")
        
        // Assert
        #expect(!album.tags.contains("タグ1"))
        #expect(album.tags.contains("タグ2"))
    }
    
    @Test("Album toggleArchiveStatusテスト")
    func testAlbumToggleArchiveStatus() async throws {
        // Arrange
        let album = Album(name: "テストアルバム")
        #expect(album.isArchived == false)
        
        // Act & Assert
        album.toggleArchiveStatus()
        #expect(album.isArchived == true)
        
        album.toggleArchiveStatus()
        #expect(album.isArchived == false)
    }
    
    @Test("Album dateRange空の場合テスト")
    func testAlbumDateRangeEmpty() async throws {
        // Arrange
        let album = Album(name: "空のアルバム")
        
        // Act & Assert
        #expect(album.dateRange == "写真なし")
    }
    
    @Test("Album updateCoverPhotoテスト")
    func testAlbumUpdateCoverPhoto() async throws {
        // Arrange
        let album = Album(name: "テストアルバム")
        let photoID = "test-photo-id"
        
        // Act
        album.updateCoverPhoto(to: photoID)
        
        // Assert
        #expect(album.coverPhotoID == photoID)
    }
    
    @Test("Album Sample Data作成テスト")
    func testAlbumSampleDataCreation() async throws {
        // Act
        let sampleAlbum = Album.createSampleAlbum()
        
        // Assert
        #expect(sampleAlbum.name == "家族旅行 2024")
        #expect(sampleAlbum.albumDescription == "夏休みの思い出いっぱいの旅行")
        #expect(sampleAlbum.tags.contains("旅行"))
        #expect(sampleAlbum.tags.contains("夏休み"))
        #expect(sampleAlbum.tags.contains("2024"))
    }
    
    @Test("Album Sample Albums配列テスト")
    func testAlbumSampleAlbumsArray() async throws {
        // Act
        let sampleAlbums = Album.sampleAlbums
        
        // Assert
        #expect(sampleAlbums.count == 5)
        #expect(sampleAlbums.contains { $0.name == "家族旅行 2024" })
        #expect(sampleAlbums.contains { $0.name == "誕生日会" })
        #expect(sampleAlbums.contains { $0.name == "子供の成長" })
        #expect(sampleAlbums.contains { $0.name == "季節の行事" })
        #expect(sampleAlbums.contains { $0.name == "ペット" })
    }
}