//
//  FamilyAlbumViewModel.swift
//  AsaFamilyAlbum
//
//  Created on 2025/09/05
//  601番目の@Observableパターン実装
//

import Foundation
import SwiftUI
import SwiftData
import Photos

@Observable
final class FamilyAlbumViewModel: Sendable {
    
    // MARK: - Properties
    
    private(set) var albums: [Album] = []
    private(set) var recentAlbums: [Album] = []
    private(set) var favoritePhotos: [Photo] = []
    private(set) var allPhotos: [Photo] = []
    private(set) var familyMembers: [FamilyMember] = []
    private(set) var statistics: FamilyAlbumStatistics?
    
    // UI States
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    private(set) var photoLibraryAccess: Bool = false
    
    // Selection States
    var selectedAlbum: Album?
    var selectedPhoto: Photo?
    var selectedFamilyMember: FamilyMember?
    
    // Search and Filter
    var searchText: String = ""
    var selectedCategory: String = "全て"
    var dateFilter: DateFilter = .all
    var showFavoritesOnly: Bool = false
    
    // Services
    private let photoLibraryService: PhotoLibraryService
    let dataService: DataPersistenceService
    
    // MARK: - Enums
    
    enum DateFilter: String, CaseIterable {
        case all = "全て"
        case today = "今日"
        case thisWeek = "今週"
        case thisMonth = "今月"
        case thisYear = "今年"
        case custom = "カスタム"
        
        var dateRange: (start: Date?, end: Date?) {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .all:
                return (nil, nil)
            case .today:
                let start = calendar.startOfDay(for: now)
                let end = calendar.date(byAdding: .day, value: 1, to: start)
                return (start, end)
            case .thisWeek:
                let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start
                return (start, now)
            case .thisMonth:
                let start = calendar.dateInterval(of: .month, for: now)?.start
                return (start, now)
            case .thisYear:
                let start = calendar.dateInterval(of: .year, for: now)?.start
                return (start, now)
            case .custom:
                return (nil, nil)
            }
        }
    }
    
    // MARK: - Initialization
    
    init(
        photoLibraryService: PhotoLibraryService = PhotoLibraryService.shared,
        dataService: DataPersistenceService = DataPersistenceService.shared
    ) {
        self.photoLibraryService = photoLibraryService
        self.dataService = dataService
        
        Task { @MainActor in
            await loadInitialData()
        }
    }
    
    // MARK: - Setup
    
    @MainActor
    func loadInitialData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // サンプルデータのセットアップ
            try await dataService.setupSampleData()
            
            // データの読み込み
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadAlbums() }
                group.addTask { await self.loadFamilyMembers() }
                group.addTask { await self.loadStatistics() }
            }
            
            isLoading = false
        } catch {
            errorMessage = "初期データの読み込みに失敗しました: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Photo Library Access
    
    @MainActor
    func requestPhotoLibraryAccess() {
        Task {
            let granted = await photoLibraryService.requestPhotoLibraryAccess()
            photoLibraryAccess = granted
            
            if granted {
                await photoLibraryService.loadPhotos()
                await syncPhotosWithLibrary()
            }
        }
    }
    
    @MainActor
    private func syncPhotosWithLibrary() async {
        // PhotosKitの写真をSwift Dataと同期
        let assets = photoLibraryService.assets
        var newPhotos: [Photo] = []
        
        for asset in assets.prefix(100) { // パフォーマンスのため最初の100枚のみ
            let photo = photoLibraryService.createPhoto(from: asset)
            newPhotos.append(photo)
        }
        
        do {
            try await dataService.batchSavePhotos(newPhotos)
            await loadAllPhotos()
        } catch {
            errorMessage = "写真の同期に失敗しました: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Data Loading
    
    @MainActor
    func loadAlbums() async {
        do {
            albums = try await dataService.fetchAllAlbums()
            recentAlbums = try await dataService.fetchRecentAlbums(limit: 5)
        } catch {
            errorMessage = "アルバムの読み込みに失敗しました: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func loadAllPhotos() async {
        do {
            allPhotos = try await dataService.fetchRecentPhotos(limit: 1000)
            favoritePhotos = try await dataService.fetchFavoritePhotos()
        } catch {
            errorMessage = "写真の読み込みに失敗しました: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func loadFamilyMembers() async {
        do {
            familyMembers = try await dataService.fetchAllFamilyMembers()
        } catch {
            errorMessage = "家族メンバーの読み込みに失敗しました: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func loadStatistics() async {
        do {
            statistics = try await dataService.getStatistics()
        } catch {
            errorMessage = "統計情報の読み込みに失敗しました: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Album Operations
    
    @MainActor
    func createAlbum(name: String, description: String?, tags: [String] = []) async {
        let album = Album(name: name, albumDescription: description, tags: tags)
        
        do {
            try await dataService.saveAlbum(album)
            await loadAlbums()
        } catch {
            errorMessage = "アルバムの作成に失敗しました: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func updateAlbum(_ album: Album, name: String? = nil, description: String? = nil) async {
        if let name = name {
            album.name = name
        }
        if let description = description {
            album.albumDescription = description
        }
        album.updateTimestamp()
        
        await loadAlbums()
    }
    
    @MainActor
    func deleteAlbum(_ album: Album) async {
        do {
            try await dataService.deleteAlbum(album)
            await loadAlbums()
        } catch {
            errorMessage = "アルバムの削除に失敗しました: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func addPhotoToAlbum(photo: Photo, album: Album) async {
        photo.album = album
        photo.updateTimestamp()
        album.updateTimestamp()
        
        await loadAlbums()
        await loadAllPhotos()
    }

    @MainActor
    func addPhotoFromImage(_ image: UIImage, to album: Album) async {
        // 1. 画像をローカルストレージに保存
        guard let imagePath = await ImageStorageService.shared.saveImage(image) else {
            errorMessage = "画像の保存に失敗しました"
            return
        }

        // 2. Photoモデルを作成
        let photo = Photo(
            assetID: UUID().uuidString,
            createdAt: Date(),
            location: nil
        )
        photo.localImagePath = imagePath
        photo.album = album
        photo.updateTimestamp()
        album.updateTimestamp()

        // 3. Swift Dataに保存
        do {
            try await dataService.savePhoto(photo)
            await loadAlbums()
            await loadAllPhotos()
        } catch {
            errorMessage = "写真の追加に失敗しました: \(error.localizedDescription)"
            // 保存失敗時は画像ファイルも削除
            _ = ImageStorageService.shared.deleteImage(at: imagePath)
        }
    }
    
    // MARK: - Photo Operations
    
    @MainActor
    func togglePhotoFavorite(_ photo: Photo) async {
        photo.toggleFavorite()
        
        await loadAllPhotos()
    }
    
    @MainActor
    func addTagToPhoto(_ photo: Photo, tag: String) async {
        photo.addTag(tag)
        await loadAllPhotos()
    }
    
    @MainActor
    func removeTagFromPhoto(_ photo: Photo, tag: String) async {
        photo.removeTag(tag)
        await loadAllPhotos()
    }
    
    @MainActor
    func addCommentToPhoto(_ photo: Photo, text: String, author: String) async {
        photo.addComment(text, author: author)
        
        do {
            try await dataService.savePhoto(photo)
        } catch {
            errorMessage = "コメントの追加に失敗しました: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func tagFamilyMemberInPhoto(_ photo: Photo, member: FamilyMember) async {
        photo.tagFamilyMember(member)
        await loadAllPhotos()
    }
    
    @MainActor
    func deletePhoto(_ photo: Photo) async {
        do {
            try await dataService.deletePhoto(photo)
            await loadAllPhotos()
        } catch {
            errorMessage = "写真の削除に失敗しました: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Family Member Operations
    
    @MainActor
    func createFamilyMember(
        name: String,
        nickname: String? = nil,
        relationship: String,
        birthDate: Date? = nil,
        description: String? = nil,
        color: String = "AsaMutedSage"
    ) async {
        let member = FamilyMember(
            name: name,
            nickname: nickname,
            relationship: relationship,
            birthDate: birthDate,
            profileDescription: description,
            color: color
        )
        
        do {
            try await dataService.saveFamilyMember(member)
            await loadFamilyMembers()
        } catch {
            errorMessage = "家族メンバーの作成に失敗しました: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func updateFamilyMember(
        _ member: FamilyMember,
        name: String? = nil,
        nickname: String? = nil,
        relationship: String? = nil,
        birthDate: Date? = nil,
        description: String? = nil,
        color: String? = nil
    ) async {
        member.updateProfile(
            name: name,
            nickname: nickname,
            relationship: relationship,
            birthDate: birthDate,
            profileDescription: description,
            color: color
        )
        
        await loadFamilyMembers()
    }
    
    @MainActor
    func deleteFamilyMember(_ member: FamilyMember) async {
        do {
            try await dataService.deleteFamilyMember(member)
            await loadFamilyMembers()
        } catch {
            errorMessage = "家族メンバーの削除に失敗しました: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Search and Filter
    
    var filteredAlbums: [Album] {
        var filtered = albums
        
        if !searchText.isEmpty {
            filtered = filtered.filter { album in
                album.name.localizedStandardContains(searchText) ||
                album.albumDescription?.localizedStandardContains(searchText) == true ||
                album.tags.contains { $0.localizedStandardContains(searchText) }
            }
        }
        
        return filtered
    }
    
    var filteredPhotos: [Photo] {
        var filtered = allPhotos
        
        // お気に入りフィルター
        if showFavoritesOnly {
            filtered = filtered.filter { $0.isFavorite }
        }
        
        // テキスト検索
        if !searchText.isEmpty {
            filtered = filtered.filter { photo in
                photo.title?.localizedStandardContains(searchText) == true ||
                photo.userDescription?.localizedStandardContains(searchText) == true ||
                photo.location?.localizedStandardContains(searchText) == true ||
                photo.tags.contains { $0.localizedStandardContains(searchText) }
            }
        }
        
        // 日付フィルター
        let (startDate, endDate) = dateFilter.dateRange
        if let startDate = startDate {
            filtered = filtered.filter { $0.createdAt >= startDate }
        }
        if let endDate = endDate {
            filtered = filtered.filter { $0.createdAt < endDate }
        }
        
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }
    
    @MainActor
    func searchPhotos(text: String) async {
        searchText = text
    }
    
    @MainActor
    func clearSearch() {
        searchText = ""
        selectedCategory = "全て"
        dateFilter = .all
        showFavoritesOnly = false
    }
    
    // MARK: - Image Loading
    
    func loadImage(for photo: Photo, size: CGSize = CGSize(width: 300, height: 300)) async -> UIImage? {
        // 優先順位1: ローカル保存画像
        if let localPath = photo.localImagePath {
            return await ImageStorageService.shared.loadImage(from: localPath, targetSize: size)
        }

        // 優先順位2: PHAsset fallback（既存写真）
        guard let asset = photoLibraryService.getAsset(for: photo) else {
            return nil
        }

        return await photoLibraryService.loadImage(for: asset, targetSize: size)
    }
    
    func loadFullSizeImage(for photo: Photo) async -> UIImage? {
        // 優先順位1: ローカル保存画像
        if let localPath = photo.localImagePath {
            return await ImageStorageService.shared.loadImage(from: localPath)
        }

        // 優先順位2: PHAsset fallback（既存写真）
        guard let asset = photoLibraryService.getAsset(for: photo) else {
            return nil
        }

        return await photoLibraryService.loadFullSizeImage(for: asset)
    }
    
    // MARK: - Export
    
    @MainActor
    func exportAlbum(_ album: Album) async -> AlbumExportData? {
        do {
            return try await dataService.exportAlbumData(album)
        } catch {
            errorMessage = "アルバムのエクスポートに失敗しました: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Error Handling
    
    @MainActor
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Computed Properties
    
    var hasData: Bool {
        !albums.isEmpty || !allPhotos.isEmpty
    }
    
    var recentPhotos: [Photo] {
        Array(allPhotos.prefix(20))
    }
    
    var photosByMonth: [String: [Photo]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        formatter.locale = Locale(identifier: "ja_JP")
        
        return Dictionary(grouping: allPhotos) { photo in
            formatter.string(from: photo.createdAt)
        }
    }
    
    var albumsWithPhotoCounts: [(album: Album, count: Int)] {
        albums.map { album in
            (album: album, count: album.photos.count)
        }
        .sorted { $0.count > $1.count }
    }
}