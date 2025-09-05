//
//  PhotoModelTests.swift
//  AsaFamilyAlbumTests
//
//  Created on 2025/09/05
//

import Testing
import Foundation
import SwiftData
@testable import AsaFamilyAlbum

struct PhotoModelTests {
    
    @Test("Photo初期化テスト")
    func testPhotoInitialization() async throws {
        // Arrange & Act
        let photo = Photo(
            assetIdentifier: "test-asset-123",
            title: "テスト写真",
            userDescription: "テスト用の写真です"
        )
        
        // Assert
        #expect(photo.assetIdentifier == "test-asset-123")
        #expect(photo.title == "テスト写真")
        #expect(photo.userDescription == "テスト用の写真です")
        #expect(photo.isFavorite == false)
        #expect(photo.tags.isEmpty)
        #expect(photo.comments.isEmpty)
        #expect(photo.isHidden == false)
    }
    
    @Test("Photo toggleFavoriteテスト")
    func testPhotoToggleFavorite() async throws {
        // Arrange
        let photo = Photo(assetIdentifier: "test-asset")
        #expect(photo.isFavorite == false)
        
        // Act & Assert
        photo.toggleFavorite()
        #expect(photo.isFavorite == true)
        
        photo.toggleFavorite()
        #expect(photo.isFavorite == false)
    }
    
    @Test("Photo addTagテスト")
    func testPhotoAddTag() async throws {
        // Arrange
        let photo = Photo(assetIdentifier: "test-asset")
        
        // Act
        photo.addTag("風景")
        photo.addTag("家族")
        
        // Assert
        #expect(photo.tags.contains("風景"))
        #expect(photo.tags.contains("家族"))
        
        // 同じタグを追加しても重複しない
        photo.addTag("風景")
        let tagCount = photo.tags.filter { $0 == "風景" }.count
        #expect(tagCount == 1)
    }
    
    @Test("Photo removeTagテスト")
    func testPhotoRemoveTag() async throws {
        // Arrange
        let photo = Photo(assetIdentifier: "test-asset")
        photo.addTag("タグ1")
        photo.addTag("タグ2")
        
        // Act
        photo.removeTag("タグ1")
        
        // Assert
        #expect(!photo.tags.contains("タグ1"))
        #expect(photo.tags.contains("タグ2"))
    }
    
    @Test("Photo updateTimestampテスト")
    func testPhotoUpdateTimestamp() async throws {
        // Arrange
        let photo = Photo(assetIdentifier: "test-asset")
        let originalTimestamp = photo.updatedAt
        
        // Act
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01秒
        photo.updateTimestamp()
        
        // Assert
        #expect(photo.updatedAt > originalTimestamp)
    }
    
    @Test("Photo addCommentテスト")
    func testPhotoAddComment() async throws {
        // Arrange
        let photo = Photo(assetIdentifier: "test-asset")
        
        // Act
        photo.addComment("素晴らしい写真です", author: "太郎")
        
        // Assert
        #expect(photo.comments.count == 1)
        
        let comment = photo.comments.first
        #expect(comment?.text == "素晴らしい写真です")
        #expect(comment?.author == "太郎")
    }
    
    @Test("Photo tagFamilyMemberテスト - FamilyMemberなしの場合")
    func testPhotoTagFamilyMemberEmpty() async throws {
        // Arrange
        let photo = Photo(assetIdentifier: "test-asset")
        let familyMember = FamilyMember(name: "太郎", relationship: "息子")
        
        // Act
        photo.tagFamilyMember(familyMember)
        
        // Assert
        #expect(photo.taggedFamilyMembers.contains(familyMember))
    }
    
    @Test("Photo toggleHiddenStatusテスト")
    func testPhotoToggleHiddenStatus() async throws {
        // Arrange
        let photo = Photo(assetIdentifier: "test-asset")
        #expect(photo.isHidden == false)
        
        // Act & Assert
        photo.toggleHiddenStatus()
        #expect(photo.isHidden == true)
        
        photo.toggleHiddenStatus()
        #expect(photo.isHidden == false)
    }
    
    @Test("Photo updateLocationテスト")
    func testPhotoUpdateLocation() async throws {
        // Arrange
        let photo = Photo(assetIdentifier: "test-asset")
        
        // Act
        photo.updateLocation("東京タワー")
        
        // Assert
        #expect(photo.location == "東京タワー")
    }
    
    @Test("Photo exifDataプロパティテスト")
    func testPhotoExifDataProperty() async throws {
        // Arrange
        let photo = Photo(assetIdentifier: "test-asset")
        let exifData = ["Camera": "iPhone 15 Pro", "ISO": "100"]
        
        // Act
        photo.exifData = exifData
        
        // Assert
        #expect(photo.exifData?["Camera"] == "iPhone 15 Pro")
        #expect(photo.exifData?["ISO"] == "100")
    }
    
    @Test("Photo複数ファミリーメンバータグテスト")
    func testPhotoMultipleFamilyMemberTags() async throws {
        // Arrange
        let photo = Photo(assetIdentifier: "test-asset")
        let member1 = FamilyMember(name: "太郎", relationship: "息子")
        let member2 = FamilyMember(name: "花子", relationship: "娘")
        
        // Act
        photo.tagFamilyMember(member1)
        photo.tagFamilyMember(member2)
        
        // Assert
        #expect(photo.taggedFamilyMembers.count == 2)
        #expect(photo.taggedFamilyMembers.contains(member1))
        #expect(photo.taggedFamilyMembers.contains(member2))
    }
}