//
//  FamilyMemberModelTests.swift
//  AsaFamilyAlbumTests
//
//  Created on 2025/09/05
//

import Testing
import Foundation
import SwiftData
@testable import AsaFamilyAlbum

struct FamilyMemberModelTests {
    
    @Test("FamilyMember初期化テスト")
    func testFamilyMemberInitialization() async throws {
        // Arrange & Act
        let member = FamilyMember(
            name: "太郎",
            nickname: "たろちゃん",
            relationship: "息子",
            birthDate: Date(timeIntervalSince1970: 946684800), // 2000年1月1日
            profileDescription: "元気な男の子",
            color: "AsaCoffeeBrown"
        )
        
        // Assert
        #expect(member.name == "太郎")
        #expect(member.nickname == "たろちゃん")
        #expect(member.relationship == "息子")
        #expect(member.profileDescription == "元気な男の子")
        #expect(member.color == "AsaCoffeeBrown")
        #expect(member.isArchived == false)
    }
    
    @Test("FamilyMember displayName - ニックネーム有りテスト")
    func testFamilyMemberDisplayNameWithNickname() async throws {
        // Arrange
        let member = FamilyMember(
            name: "太郎",
            nickname: "たろちゃん",
            relationship: "息子"
        )
        
        // Act & Assert
        #expect(member.displayName == "たろちゃん")
    }
    
    @Test("FamilyMember displayName - ニックネーム無しテスト")
    func testFamilyMemberDisplayNameWithoutNickname() async throws {
        // Arrange
        let member = FamilyMember(
            name: "太郎",
            relationship: "息子"
        )
        
        // Act & Assert
        #expect(member.displayName == "太郎")
    }
    
    @Test("FamilyMember ageCalculation - 誕生日有りテスト")
    func testFamilyMemberAgeCalculationWithBirthDate() async throws {
        // Arrange
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .year, value: -25, to: Date())!
        let member = FamilyMember(
            name: "太郎",
            relationship: "息子",
            birthDate: birthDate
        )
        
        // Act & Assert
        #expect(member.age == 25)
    }
    
    @Test("FamilyMember ageCalculation - 誕生日無しテスト")
    func testFamilyMemberAgeCalculationWithoutBirthDate() async throws {
        // Arrange
        let member = FamilyMember(
            name: "太郎",
            relationship: "息子"
        )
        
        // Act & Assert
        #expect(member.age == nil)
    }
    
    @Test("FamilyMember updateProfileテスト")
    func testFamilyMemberUpdateProfile() async throws {
        // Arrange
        let member = FamilyMember(
            name: "太郎",
            relationship: "息子"
        )
        let originalTimestamp = member.updatedAt
        
        // Act
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01秒
        member.updateProfile(
            name: "太郎2",
            nickname: "たろちゃん",
            relationship: "長男",
            profileDescription: "更新された説明"
        )
        
        // Assert
        #expect(member.name == "太郎2")
        #expect(member.nickname == "たろちゃん")
        #expect(member.relationship == "長男")
        #expect(member.profileDescription == "更新された説明")
        #expect(member.updatedAt > originalTimestamp)
    }
    
    @Test("FamilyMember updateProfile - 部分更新テスト")
    func testFamilyMemberPartialUpdateProfile() async throws {
        // Arrange
        let member = FamilyMember(
            name: "太郎",
            nickname: "たろちゃん",
            relationship: "息子",
            profileDescription: "元の説明"
        )
        
        // Act - name のみ更新
        member.updateProfile(name: "太郎2")
        
        // Assert - 他のフィールドは変更されていない
        #expect(member.name == "太郎2")
        #expect(member.nickname == "たろちゃん")
        #expect(member.relationship == "息子")
        #expect(member.profileDescription == "元の説明")
    }
    
    @Test("FamilyMember toggleArchiveStatusテスト")
    func testFamilyMemberToggleArchiveStatus() async throws {
        // Arrange
        let member = FamilyMember(name: "太郎", relationship: "息子")
        #expect(member.isArchived == false)
        
        // Act & Assert
        member.toggleArchiveStatus()
        #expect(member.isArchived == true)
        
        member.toggleArchiveStatus()
        #expect(member.isArchived == false)
    }
    
    @Test("FamilyMember Sample Data作成テスト")
    func testFamilyMemberSampleDataCreation() async throws {
        // Act
        let sampleMembers = FamilyMember.sampleFamilyMembers
        
        // Assert
        #expect(sampleMembers.count >= 4)
        #expect(sampleMembers.contains { $0.name == "父" && $0.relationship == "父" })
        #expect(sampleMembers.contains { $0.name == "母" && $0.relationship == "母" })
        #expect(sampleMembers.contains { $0.name == "太郎" && $0.relationship == "息子" })
        #expect(sampleMembers.contains { $0.name == "花子" && $0.relationship == "娘" })
    }
    
    @Test("FamilyMember 色設定テスト")
    func testFamilyMemberColorProperty() async throws {
        // Arrange
        let member = FamilyMember(
            name: "太郎",
            relationship: "息子",
            color: "AsaMutedSage"
        )
        
        // Act & Assert
        #expect(member.color == "AsaMutedSage")
        
        // 色を更新
        member.updateProfile(color: "AsaCoffeeBrown")
        #expect(member.color == "AsaCoffeeBrown")
    }
    
    @Test("FamilyMember 誕生日更新テスト")
    func testFamilyMemberBirthDateUpdate() async throws {
        // Arrange
        let member = FamilyMember(name: "太郎", relationship: "息子")
        let newBirthDate = Date(timeIntervalSince1970: 946684800) // 2000年1月1日
        
        // Act
        member.updateProfile(birthDate: newBirthDate)
        
        // Assert
        #expect(member.birthDate == newBirthDate)
    }
}