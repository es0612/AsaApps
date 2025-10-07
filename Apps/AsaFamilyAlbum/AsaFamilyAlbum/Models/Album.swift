//
//  Album.swift
//  AsaFamilyAlbum
//
//  Created on 2025/09/05
//

import Foundation
import SwiftData

@Model
final class Album: Identifiable {
    var id: UUID
    var name: String
    var albumDescription: String?
    var coverPhotoID: String?
    var createdAt: Date
    var updatedAt: Date
    var tags: [String]
    var isArchived: Bool
    
    // Swift Dataリレーション
    @Relationship(deleteRule: .cascade, inverse: \Photo.album)
    var photos: [Photo] = []
    
    init(
        name: String,
        albumDescription: String? = nil,
        coverPhotoID: String? = nil,
        tags: [String] = [],
        isArchived: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.albumDescription = albumDescription
        self.coverPhotoID = coverPhotoID
        self.createdAt = Date()
        self.updatedAt = Date()
        self.tags = tags
        self.isArchived = isArchived
    }
    
    // MARK: - Computed Properties
    
    var photoCount: Int {
        photos.count
    }
    
    var favoritePhotos: [Photo] {
        photos.filter { $0.isFavorite }
    }
    
    var mostRecentPhoto: Photo? {
        photos.max { $0.createdAt < $1.createdAt }
    }
    
    var recentPhotos: [Photo] {
        photos.sorted { $0.createdAt > $1.createdAt }
    }
    
    var dateRange: String {
        guard !photos.isEmpty else { return "写真なし" }
        
        let sortedPhotos = photos.sorted { $0.createdAt < $1.createdAt }
        guard let firstPhoto = sortedPhotos.first,
              let lastPhoto = sortedPhotos.last else { return "不明" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        
        if Calendar.current.isDate(firstPhoto.createdAt, inSameDayAs: lastPhoto.createdAt) {
            return formatter.string(from: firstPhoto.createdAt)
        } else {
            return "\(formatter.string(from: firstPhoto.createdAt)) - \(formatter.string(from: lastPhoto.createdAt))"
        }
    }
    
    // MARK: - Methods
    
    func updateTimestamp() {
        updatedAt = Date()
    }
    
    func addTag(_ tag: String) {
        if !tags.contains(tag) {
            tags.append(tag)
            updateTimestamp()
        }
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        updateTimestamp()
    }
    
    func toggleArchiveStatus() {
        isArchived.toggle()
        updateTimestamp()
    }
    
    func updateCoverPhoto(to photoID: String?) {
        coverPhotoID = photoID
        updateTimestamp()
    }
}

// MARK: - Sample Data

extension Album {
    static func createSampleAlbum() -> Album {
        let album = Album(
            name: "家族旅行 2024",
            albumDescription: "夏休みの思い出いっぱいの旅行",
            tags: ["旅行", "夏休み", "2024"]
        )
        return album
    }
    
    static let sampleAlbums: [Album] = [
        Album(name: "家族旅行 2024", albumDescription: "夏休みの旅行", tags: ["旅行", "夏"]),
        Album(name: "誕生日会", albumDescription: "父の誕生日パーティー", tags: ["誕生日", "お祝い"]),
        Album(name: "子供の成長", albumDescription: "日々の成長記録", tags: ["成長", "日常"]),
        Album(name: "季節の行事", albumDescription: "お花見やお祭りなど", tags: ["季節", "イベント"]),
        Album(name: "ペット", albumDescription: "愛犬の日常", tags: ["ペット", "日常"])
    ]
}