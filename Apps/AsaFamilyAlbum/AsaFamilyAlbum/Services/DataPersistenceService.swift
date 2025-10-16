//
//  DataPersistenceService.swift
//  AsaFamilyAlbum
//
//  Created on 2025/09/05
//

import Foundation
import SwiftData
import SwiftUI

final class DataPersistenceService: ObservableObject {
    static let shared = DataPersistenceService()

    private var modelContext: ModelContext?

    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    init() {
        // ModelContextは外部から設定されるため、ここでは初期化しない
    }

    // MARK: - Setup

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Album Operations
    
    @MainActor
    func saveAlbum(_ album: Album) throws {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        context.insert(album)
        try context.save()
    }
    
    @MainActor
    func fetchAllAlbums() throws -> [Album] {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        let descriptor = FetchDescriptor<Album>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    @MainActor
    func fetchRecentAlbums(limit: Int = 5) throws -> [Album] {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        var descriptor = FetchDescriptor<Album>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        return try context.fetch(descriptor)
    }
    
    @MainActor
    func deleteAlbum(_ album: Album) throws {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        context.delete(album)
        try context.save()
    }
    
    @MainActor
    func searchAlbums(by searchText: String) throws -> [Album] {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        let descriptor = FetchDescriptor<Album>(
            predicate: #Predicate { album in
                album.name.localizedStandardContains(searchText) ||
                (album.albumDescription?.localizedStandardContains(searchText) ?? false) ||
                album.tags.contains { $0.localizedStandardContains(searchText) }
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    // MARK: - Photo Operations
    
    @MainActor
    func savePhoto(_ photo: Photo) throws {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        context.insert(photo)
        try context.save()
    }
    
    @MainActor
    func fetchPhotosInAlbum(_ album: Album) throws -> [Photo] {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        let albumId = album.id
        let descriptor = FetchDescriptor<Photo>(
            predicate: #Predicate { photo in
                photo.album?.id == albumId
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    @MainActor
    func fetchFavoritePhotos() throws -> [Photo] {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        let descriptor = FetchDescriptor<Photo>(
            predicate: #Predicate { $0.isFavorite },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    @MainActor
    func fetchRecentPhotos(limit: Int = 20) throws -> [Photo] {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        var descriptor = FetchDescriptor<Photo>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        return try context.fetch(descriptor)
    }
    
    @MainActor
    func searchPhotos(
        byText searchText: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        tags: [String] = [],
        familyMembers: [FamilyMember] = []
    ) throws -> [Photo] {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        var predicates: [Predicate<Photo>] = []
        
        // テキスト検索
        if let searchText = searchText, !searchText.isEmpty {
            let textPredicate = #Predicate<Photo> { photo in
                (photo.title?.localizedStandardContains(searchText) ?? false) ||
                (photo.userDescription?.localizedStandardContains(searchText) ?? false) ||
                (photo.location?.localizedStandardContains(searchText) ?? false)
            }
            predicates.append(textPredicate)
        }
        
        // 日付範囲検索
        if let startDate = startDate {
            let startPredicate = #Predicate<Photo> { $0.createdAt >= startDate }
            predicates.append(startPredicate)
        }
        
        if let endDate = endDate {
            let endPredicate = #Predicate<Photo> { $0.createdAt <= endDate }
            predicates.append(endPredicate)
        }
        
        // タグ検索
        if !tags.isEmpty {
            let tagPredicate = #Predicate<Photo> { photo in
                tags.allSatisfy { tag in photo.tags.contains(tag) }
            }
            predicates.append(tagPredicate)
        }
        
        let finalPredicate = predicates.isEmpty ? nil : 
            predicates.reduce(predicates.first!) { result, predicate in
                #Predicate<Photo> { photo in
                    result.evaluate(photo) && predicate.evaluate(photo)
                }
            }
        
        let descriptor = FetchDescriptor<Photo>(
            predicate: finalPredicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    @MainActor
    func deletePhoto(_ photo: Photo) throws {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        context.delete(photo)
        try context.save()
    }
    
    // MARK: - Comment Operations
    
    @MainActor
    func saveComment(_ comment: Comment) throws {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        context.insert(comment)
        try context.save()
    }
    
    @MainActor
    func fetchCommentsForPhoto(_ photo: Photo) throws -> [Comment] {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        let photoId = photo.id
        let descriptor = FetchDescriptor<Comment>(
            predicate: #Predicate { comment in
                comment.photo?.id == photoId
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        
        return try context.fetch(descriptor)
    }
    
    @MainActor
    func deleteComment(_ comment: Comment) throws {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        context.delete(comment)
        try context.save()
    }
    
    // MARK: - FamilyMember Operations
    
    @MainActor
    func saveFamilyMember(_ member: FamilyMember) throws {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        context.insert(member)
        try context.save()
    }
    
    @MainActor
    func fetchAllFamilyMembers() throws -> [FamilyMember] {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        let descriptor = FetchDescriptor<FamilyMember>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        
        return try context.fetch(descriptor)
    }
    
    @MainActor
    func deleteFamilyMember(_ member: FamilyMember) throws {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        context.delete(member)
        try context.save()
    }
    
    // MARK: - Statistics
    
    @MainActor
    func getStatistics() throws -> FamilyAlbumStatistics {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        let albumCount = try context.fetchCount(FetchDescriptor<Album>())
        let photoCount = try context.fetchCount(FetchDescriptor<Photo>())
        let favoriteCount = try context.fetchCount(
            FetchDescriptor<Photo>(predicate: #Predicate { $0.isFavorite })
        )
        let memberCount = try context.fetchCount(FetchDescriptor<FamilyMember>())
        let commentCount = try context.fetchCount(FetchDescriptor<Comment>())
        
        return FamilyAlbumStatistics(
            totalAlbums: albumCount,
            totalPhotos: photoCount,
            favoritePhotos: favoriteCount,
            familyMembers: memberCount,
            totalComments: commentCount
        )
    }
    
    // MARK: - Data Export/Import
    
    @MainActor
    func exportAlbumData(_ album: Album) throws -> AlbumExportData {
        let photos = try fetchPhotosInAlbum(album)
        var photoData: [PhotoExportData] = []
        
        for photo in photos {
            let comments = try fetchCommentsForPhoto(photo)
            photoData.append(PhotoExportData(
                photo: photo,
                comments: comments
            ))
        }
        
        return AlbumExportData(
            album: album,
            photos: photoData,
            exportDate: Date()
        )
    }
    
    // MARK: - Batch Operations
    
    @MainActor
    func batchSavePhotos(_ photos: [Photo]) throws {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        guard !photos.isEmpty else { return }
        
        let assetIDs = photos.map { $0.assetID }
        let existingDescriptor = FetchDescriptor<Photo>(
            predicate: #Predicate { photo in
                assetIDs.contains(photo.assetID)
            }
        )
        let existingPhotos = try context.fetch(existingDescriptor)
        let existingAssetIDs = Set(existingPhotos.map { $0.assetID })
        
        let newPhotos = photos.filter { !existingAssetIDs.contains($0.assetID) }
        guard !newPhotos.isEmpty else { return }
        
        for photo in newPhotos {
            context.insert(photo)
        }
        
        try context.save()
    }
    
    @MainActor
    func removeDuplicatePhotos() throws -> Int {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }
        
        let descriptor = FetchDescriptor<Photo>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let photos = try context.fetch(descriptor)
        
        var seenAssetIDs: Set<String> = []
        var duplicates: [Photo] = []
        
        for photo in photos {
            if seenAssetIDs.insert(photo.assetID).inserted {
                continue
            }
            duplicates.append(photo)
        }
        
        guard !duplicates.isEmpty else { return 0 }
        
        for duplicate in duplicates {
            context.delete(duplicate)
        }
        
        try context.save()
        return duplicates.count
    }
    
    @MainActor
    func setupSampleData() throws {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }

        // 既存データがあるかチェック
        let existingAlbums = try context.fetchCount(FetchDescriptor<Album>())
        guard existingAlbums == 0 else { return }

        // サンプル家族メンバーを作成
        let familyMembers = FamilyMember.sampleFamilyMembers
        for member in familyMembers {
            context.insert(member)
        }

        // サンプルアルバムを作成
        let sampleAlbums = Album.sampleAlbums
        for album in sampleAlbums {
            context.insert(album)
        }

        try context.save()
    }

    // MARK: - Data Management

    /// すべてのデータをリセットして、サンプルデータを再セットアップ
    /// - Note: デバッグ用途。古い壊れたデータをクリアする際に使用
    @MainActor
    func resetAllData() throws {
        guard let context = modelContext else {
            throw DataPersistenceError.contextNotAvailable
        }

        // すべてのデータを削除
        try context.delete(model: Album.self)
        try context.delete(model: Photo.self)
        try context.delete(model: Comment.self)
        try context.delete(model: FamilyMember.self)

        try context.save()

        // サンプルデータを再セットアップ
        try setupSampleData()
    }
}

// MARK: - Data Structures

struct FamilyAlbumStatistics {
    let totalAlbums: Int
    let totalPhotos: Int
    let favoritePhotos: Int
    let familyMembers: Int
    let totalComments: Int
    
    var favoritePercentage: Double {
        guard totalPhotos > 0 else { return 0 }
        return (Double(favoritePhotos) / Double(totalPhotos)) * 100
    }
    
    var averagePhotosPerAlbum: Double {
        guard totalAlbums > 0 else { return 0 }
        return Double(totalPhotos) / Double(totalAlbums)
    }
}

struct AlbumExportData { // TODO: Codable実装を後で追加
    let album: Album
    let photos: [PhotoExportData]
    let exportDate: Date
}

struct PhotoExportData { // TODO: Codable実装を後で追加
    let photo: Photo
    let comments: [Comment]
}

// MARK: - Error Types

enum DataPersistenceError: Error, LocalizedError {
    case contextNotAvailable
    case saveFailed
    case fetchFailed
    case deleteFailed
    case exportFailed
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "データベースコンテキストが利用できません"
        case .saveFailed:
            return "データの保存に失敗しました"
        case .fetchFailed:
            return "データの取得に失敗しました"
        case .deleteFailed:
            return "データの削除に失敗しました"
        case .exportFailed:
            return "データのエクスポートに失敗しました"
        }
    }
}
