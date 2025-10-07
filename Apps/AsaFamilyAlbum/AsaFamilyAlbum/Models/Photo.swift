//
//  Photo.swift
//  AsaFamilyAlbum
//
//  Created on 2025/09/05
//

import Foundation
import SwiftData
import Photos

@Model
final class Photo: Identifiable {
    var id: UUID
    var assetID: String  // PhotosKitのPHAssetのlocalIdentifier
    var title: String?
    var userDescription: String?
    var createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool
    var tags: [String]
    var location: String?
    var cameraMake: String?
    var cameraModel: String?
    var aperture: String?
    var shutterSpeed: String?
    var iso: String?
    
    // Swift Dataリレーション
    var album: Album?
    
    @Relationship(deleteRule: .cascade, inverse: \Comment.photo)
    var comments: [Comment] = []
    
    @Relationship(inverse: \FamilyMember.taggedPhotos)
    var taggedFamilyMembers: [FamilyMember] = []
    
    init(
        assetID: String,
        title: String? = nil,
        userDescription: String? = nil,
        createdAt: Date = Date(),
        isFavorite: Bool = false,
        tags: [String] = [],
        location: String? = nil
    ) {
        self.id = UUID()
        self.assetID = assetID
        self.title = title
        self.userDescription = userDescription
        self.createdAt = createdAt
        self.updatedAt = Date()
        self.isFavorite = isFavorite
        self.tags = tags
        self.location = location
    }
    
    // MARK: - Computed Properties
    
    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: createdAt)
    }
    
    var hasExifData: Bool {
        cameraMake != nil || cameraModel != nil || aperture != nil || shutterSpeed != nil || iso != nil
    }
    
    var exifSummary: String {
        var components: [String] = []
        
        if let make = cameraMake, let model = cameraModel {
            components.append("\(make) \(model)")
        }
        
        if let aperture = aperture {
            components.append("f/\(aperture)")
        }
        
        if let shutterSpeed = shutterSpeed {
            components.append("\(shutterSpeed)s")
        }
        
        if let iso = iso {
            components.append("ISO \(iso)")
        }
        
        return components.joined(separator: " • ")
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: createdAt)
    }
    
    // MARK: - Methods
    
    func updateTimestamp() {
        updatedAt = Date()
    }
    
    func toggleFavorite() {
        isFavorite.toggle()
        updateTimestamp()
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
    
    func updateExifData(from asset: PHAsset) {
        // PHAssetからEXIFデータを取得して更新
        // 実際の実装ではPHImageManagerを使用して取得
        if let location = asset.location {
            // 緯度経度から住所を取得する処理を追加予定
        }
        updateTimestamp()
    }
    
    func addComment(_ text: String, author: String) {
        let comment = Comment(text: text, author: author)
        comment.photo = self
        comments.append(comment)
        updateTimestamp()
    }
    
    func tagFamilyMember(_ member: FamilyMember) {
        if !taggedFamilyMembers.contains(member) {
            taggedFamilyMembers.append(member)
            updateTimestamp()
        }
    }
    
    func untagFamilyMember(_ member: FamilyMember) {
        taggedFamilyMembers.removeAll { $0.id == member.id }
        updateTimestamp()
    }
}

// MARK: - Sample Data

extension Photo {
    static func createSamplePhoto(assetID: String = "sample-asset-id") -> Photo {
        let photo = Photo(
            assetID: assetID,
            title: "美しい夕日",
            userDescription: "家族で見た素晴らしい夕日",
            createdAt: Date().addingTimeInterval(-86400), // 1日前
            isFavorite: true,
            tags: ["夕日", "風景", "家族"],
            location: "湘南ビーチ"
        )
        photo.cameraMake = "Apple"
        photo.cameraModel = "iPhone 15 Pro"
        photo.aperture = "1.8"
        photo.shutterSpeed = "1/1000"
        photo.iso = "100"
        return photo
    }
}