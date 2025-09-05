//
//  CommentModelTests.swift
//  AsaFamilyAlbumTests
//
//  Created on 2025/09/05
//

import Testing
import Foundation
import SwiftData
@testable import AsaFamilyAlbum

struct CommentModelTests {
    
    @Test("Comment初期化テスト")
    func testCommentInitialization() async throws {
        // Arrange & Act
        let comment = Comment(
            text: "素晴らしい写真ですね！",
            author: "太郎"
        )
        
        // Assert
        #expect(comment.text == "素晴らしい写真ですね！")
        #expect(comment.author == "太郎")
        #expect(comment.createdAt <= Date())
        #expect(comment.updatedAt <= Date())
        #expect(comment.isLiked == false)
        #expect(comment.likes == 0)
    }
    
    @Test("Comment toggleLikeテスト")
    func testCommentToggleLike() async throws {
        // Arrange
        let comment = Comment(text: "テストコメント", author: "太郎")
        #expect(comment.isLiked == false)
        #expect(comment.likes == 0)
        
        // Act & Assert - いいねを付ける
        comment.toggleLike()
        #expect(comment.isLiked == true)
        #expect(comment.likes == 1)
        
        // Act & Assert - いいねを外す
        comment.toggleLike()
        #expect(comment.isLiked == false)
        #expect(comment.likes == 0)
    }
    
    @Test("Comment updateTextテスト")
    func testCommentUpdateText() async throws {
        // Arrange
        let comment = Comment(text: "元のテキスト", author: "太郎")
        let originalUpdatedAt = comment.updatedAt
        
        // Act
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01秒
        comment.updateText("更新されたテキスト")
        
        // Assert
        #expect(comment.text == "更新されたテキスト")
        #expect(comment.updatedAt > originalUpdatedAt)
    }
    
    @Test("Comment 空のテキスト初期化テスト")
    func testCommentEmptyTextInitialization() async throws {
        // Arrange & Act
        let comment = Comment(text: "", author: "太郎")
        
        // Assert
        #expect(comment.text == "")
        #expect(comment.author == "太郎")
    }
    
    @Test("Comment 長いテキストテスト")
    func testCommentLongText() async throws {
        // Arrange
        let longText = String(repeating: "あ", count: 1000)
        
        // Act
        let comment = Comment(text: longText, author: "太郎")
        
        // Assert
        #expect(comment.text == longText)
        #expect(comment.text.count == 1000)
    }
    
    @Test("Comment 特殊文字テスト")
    func testCommentSpecialCharacters() async throws {
        // Arrange
        let specialText = "こんにちは！🎉✨ これは絵文字付きのコメントです 😊"
        
        // Act
        let comment = Comment(text: specialText, author: "花子")
        
        // Assert
        #expect(comment.text == specialText)
        #expect(comment.author == "花子")
    }
    
    @Test("Comment複数いいねテスト")
    func testCommentMultipleLikes() async throws {
        // Arrange
        let comment = Comment(text: "テストコメント", author: "太郎")
        
        // Act - 複数回いいねのオン/オフをテスト
        comment.toggleLike() // いいね: 1
        comment.toggleLike() // いいね: 0
        comment.toggleLike() // いいね: 1
        comment.toggleLike() // いいね: 0
        comment.toggleLike() // いいね: 1
        
        // Assert
        #expect(comment.likes == 1)
        #expect(comment.isLiked == true)
    }
    
    @Test("Comment updateTextで空のテキスト更新テスト")
    func testCommentUpdateTextWithEmptyString() async throws {
        // Arrange
        let comment = Comment(text: "元のテキスト", author: "太郎")
        
        // Act
        comment.updateText("")
        
        // Assert
        #expect(comment.text == "")
    }
    
    @Test("Comment作成時間とupdatedAt時間の関係テスト")
    func testCommentCreationAndUpdateTimeRelationship() async throws {
        // Arrange & Act
        let comment = Comment(text: "テストコメント", author: "太郎")
        let createdTime = comment.createdAt
        let initialUpdatedTime = comment.updatedAt
        
        // Assert - 初期状態ではcreatedAtとupdatedAtは同じかupdatedAtが少し後
        #expect(initialUpdatedTime >= createdTime)
        
        // Act - テキスト更新
        try await Task.sleep(nanoseconds: 10_000_000)
        comment.updateText("更新されたテキスト")
        let finalUpdatedTime = comment.updatedAt
        
        // Assert - createdAtは変更されず、updatedAtが更新される
        #expect(comment.createdAt == createdTime)
        #expect(finalUpdatedTime > initialUpdatedTime)
    }
    
    @Test("Comment作成者名の大小文字保持テスト")
    func testCommentAuthorCasePreservation() async throws {
        // Arrange & Act
        let comment1 = Comment(text: "テスト", author: "TARO")
        let comment2 = Comment(text: "テスト", author: "taro")
        let comment3 = Comment(text: "テスト", author: "Taro")
        
        // Assert
        #expect(comment1.author == "TARO")
        #expect(comment2.author == "taro")
        #expect(comment3.author == "Taro")
    }
}