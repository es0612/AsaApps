//
//  FamilyMember.swift
//  AsaFamilyAlbum
//
//  Created on 2025/09/05
//

import Foundation
import SwiftData

@Model
final class FamilyMember: Identifiable, Sendable {
    var id: UUID
    var name: String
    var nickname: String?
    var relationship: String  // "父", "母", "子供", "おじいちゃん" など
    var birthDate: Date?
    var profileDescription: String?
    var createdAt: Date
    var updatedAt: Date
    var color: String  // タグ色を指定
    var isArchived: Bool
    
    // Swift Dataリレーション（逆参照はPhoto側で定義）
    var taggedPhotos: [Photo] = []
    
    init(
        name: String,
        nickname: String? = nil,
        relationship: String,
        birthDate: Date? = nil,
        profileDescription: String? = nil,
        color: String = "AsaMutedSage",
        isArchived: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.nickname = nickname
        self.relationship = relationship
        self.birthDate = birthDate
        self.profileDescription = profileDescription
        self.createdAt = Date()
        self.updatedAt = Date()
        self.color = color
        self.isArchived = isArchived
    }
    
    // MARK: - Computed Properties
    
    var displayName: String {
        if let nickname = nickname, !nickname.isEmpty {
            return nickname
        }
        return name
    }
    
    var fullDisplayName: String {
        if let nickname = nickname, !nickname.isEmpty, nickname != name {
            return "\(name) (\(nickname))"
        }
        return name
    }
    
    var age: Int? {
        guard let birthDate = birthDate else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year
    }
    
    var ageString: String {
        if let age = age {
            return "\(age)歳"
        }
        return "年齢不明"
    }
    
    var photoCount: Int {
        taggedPhotos.count
    }
    
    var recentPhotos: [Photo] {
        taggedPhotos
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(10)
            .map { $0 }
    }
    
    var formattedBirthDate: String {
        guard let birthDate = birthDate else { return "不明" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: birthDate)
    }
    
    var relationshipIcon: String {
        switch relationship.lowercased() {
        case "父", "お父さん", "パパ":
            return "figure.stand"
        case "母", "お母さん", "ママ":
            return "figure.dress.line.vertical.figure"
        case "子供", "娘", "息子":
            return "figure.child"
        case "おじいちゃん":
            return "figure.walk"
        case "おばあちゃん":
            return "figure.walk.circle"
        case "犬", "イヌ":
            return "dog"
        case "猫", "ネコ":
            return "cat"
        default:
            return "person.circle"
        }
    }
    
    // MARK: - Methods
    
    func updateTimestamp() {
        updatedAt = Date()
    }
    
    func updateProfile(
        name: String? = nil,
        nickname: String? = nil,
        relationship: String? = nil,
        birthDate: Date? = nil,
        profileDescription: String? = nil,
        color: String? = nil
    ) {
        if let name = name { self.name = name }
        if let nickname = nickname { self.nickname = nickname }
        if let relationship = relationship { self.relationship = relationship }
        if let birthDate = birthDate { self.birthDate = birthDate }
        if let profileDescription = profileDescription { self.profileDescription = profileDescription }
        if let color = color { self.color = color }
        
        updateTimestamp()
    }
    
    func toggleArchiveStatus() {
        isArchived.toggle()
        updateTimestamp()
    }
    
    func getMostTaggedAlbum() -> Album? {
        let albums = taggedPhotos.compactMap { $0.album }
        let albumCounts = Dictionary(grouping: albums) { $0.id }
        
        return albumCounts.max { $0.value.count < $1.value.count }?.value.first
    }
}

// MARK: - Sample Data

extension FamilyMember {
    static func createSampleFamilyMember() -> FamilyMember {
        return FamilyMember(
            name: "朝活太郎",
            nickname: "パパ",
            relationship: "父",
            birthDate: Calendar.current.date(from: DateComponents(year: 1985, month: 4, day: 15)),
            profileDescription: "朝活が大好きなパパエンジニア",
            color: "AsaCoffeeBrown"
        )
    }
    
    static let sampleFamilyMembers: [FamilyMember] = [
        FamilyMember(
            name: "朝活太郎",
            nickname: "パパ",
            relationship: "父",
            birthDate: Calendar.current.date(from: DateComponents(year: 1985, month: 4, day: 15)),
            profileDescription: "朝活が大好きなパパエンジニア",
            color: "AsaCoffeeBrown"
        ),
        FamilyMember(
            name: "朝活花子",
            nickname: "ママ",
            relationship: "母",
            birthDate: Calendar.current.date(from: DateComponents(year: 1987, month: 8, day: 22)),
            profileDescription: "家族の縁の下の力持ち",
            color: "AsaMutedSage"
        ),
        FamilyMember(
            name: "朝活ひとし",
            nickname: "ひとくん",
            relationship: "子供",
            birthDate: Calendar.current.date(from: DateComponents(year: 2015, month: 12, day: 3)),
            profileDescription: "元気いっぱいの長男",
            color: "AsaSoftCream"
        ),
        FamilyMember(
            name: "朝活みゆき",
            nickname: "みゆちゃん",
            relationship: "子供",
            birthDate: Calendar.current.date(from: DateComponents(year: 2018, month: 6, day: 18)),
            profileDescription: "おしゃまが大好きな長女",
            color: "AsaMocha"
        ),
        FamilyMember(
            name: "もこ",
            relationship: "ペット",
            birthDate: Calendar.current.date(from: DateComponents(year: 2020, month: 3, day: 10)),
            profileDescription: "家族のアイドル、柴犬",
            color: "AsaDarkSlate"
        )
    ]
}