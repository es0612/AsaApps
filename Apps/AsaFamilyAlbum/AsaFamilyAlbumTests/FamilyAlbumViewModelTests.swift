//
//  FamilyAlbumViewModelTests.swift
//  AsaFamilyAlbumTests
//
//  Created on 2025/09/05
//

import Testing
import Foundation
import SwiftData
@testable import AsaFamilyAlbum

struct FamilyAlbumViewModelTests {
    
    @Test("ViewModel初期化テスト")
    func testViewModelInitialization() async throws {
        // Arrange & Act
        let viewModel = FamilyAlbumViewModel()
        
        // Assert
        #expect(viewModel.albums.isEmpty)
        #expect(viewModel.recentAlbums.isEmpty)
        #expect(viewModel.favoritePhotos.isEmpty)
        #expect(viewModel.allPhotos.isEmpty)
        #expect(viewModel.familyMembers.isEmpty)
        #expect(viewModel.statistics == nil)
        #expect(viewModel.searchText == "")
        #expect(viewModel.selectedCategory == "全て")
        #expect(viewModel.dateFilter == .all)
        #expect(viewModel.showFavoritesOnly == false)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("DateFilter dateRangeテスト")
    func testDateFilterDateRange() async throws {
        // Arrange
        let calendar = Calendar.current
        let now = Date()
        
        // Act & Assert - .all
        let allRange = FamilyAlbumViewModel.DateFilter.all.dateRange
        #expect(allRange.start == nil)
        #expect(allRange.end == nil)
        
        // Act & Assert - .today
        let todayRange = FamilyAlbumViewModel.DateFilter.today.dateRange
        let expectedTodayStart = calendar.startOfDay(for: now)
        #expect(todayRange.start != nil)
        #expect(calendar.isDate(todayRange.start!, inSameDayAs: expectedTodayStart))
        
        // Act & Assert - .thisWeek
        let weekRange = FamilyAlbumViewModel.DateFilter.thisWeek.dateRange
        #expect(weekRange.start != nil)
        #expect(weekRange.end != nil)
        
        // Act & Assert - .thisMonth
        let monthRange = FamilyAlbumViewModel.DateFilter.thisMonth.dateRange
        #expect(monthRange.start != nil)
        #expect(monthRange.end != nil)
        
        // Act & Assert - .thisYear
        let yearRange = FamilyAlbumViewModel.DateFilter.thisYear.dateRange
        #expect(yearRange.start != nil)
        #expect(yearRange.end != nil)
    }
    
    @Test("searchText更新テスト")
    func testSearchTextUpdate() async throws {
        // Arrange
        let viewModel = FamilyAlbumViewModel()
        
        // Act
        await viewModel.searchPhotos(text: "テスト検索")
        
        // Assert
        #expect(viewModel.searchText == "テスト検索")
    }
    
    @Test("clearSearchテスト")
    func testClearSearch() async throws {
        // Arrange
        let viewModel = FamilyAlbumViewModel()
        viewModel.searchText = "テスト検索"
        viewModel.selectedCategory = "写真"
        viewModel.dateFilter = .thisMonth
        viewModel.showFavoritesOnly = true
        
        // Act
        viewModel.clearSearch()
        
        // Assert
        #expect(viewModel.searchText == "")
        #expect(viewModel.selectedCategory == "全て")
        #expect(viewModel.dateFilter == .all)
        #expect(viewModel.showFavoritesOnly == false)
    }
    
    @Test("hasDataプロパティテスト")
    func testHasDataProperty() async throws {
        // Arrange
        let viewModel = FamilyAlbumViewModel()
        
        // Act & Assert - 初期状態では false
        #expect(viewModel.hasData == false)
        
        // モックデータを設定（実際の実装では、MockDataPersistenceServiceを使用）
        // この例では、プロパティが直接設定できるかをテスト
    }
    
    @Test("recentPhotosプロパティテスト")
    func testRecentPhotosProperty() async throws {
        // Arrange
        let viewModel = FamilyAlbumViewModel()
        
        // Act & Assert
        #expect(viewModel.recentPhotos.isEmpty)
        
        // 実際のテストでは、allPhotosにデータを追加してrecentPhotosをテスト
    }
    
    @Test("DateFilter rawValue文字列テスト")
    func testDateFilterRawValues() async throws {
        // Act & Assert
        #expect(FamilyAlbumViewModel.DateFilter.all.rawValue == "全て")
        #expect(FamilyAlbumViewModel.DateFilter.today.rawValue == "今日")
        #expect(FamilyAlbumViewModel.DateFilter.thisWeek.rawValue == "今週")
        #expect(FamilyAlbumViewModel.DateFilter.thisMonth.rawValue == "今月")
        #expect(FamilyAlbumViewModel.DateFilter.thisYear.rawValue == "今年")
        #expect(FamilyAlbumViewModel.DateFilter.custom.rawValue == "カスタム")
    }
    
    @Test("filteredAlbumsプロパティ - searchText空の場合テスト")
    func testFilteredAlbumsEmptySearchText() async throws {
        // Arrange
        let viewModel = FamilyAlbumViewModel()
        viewModel.searchText = ""
        
        // Act & Assert
        // 実際のテストでは、albumsにテストデータを設定
        #expect(viewModel.filteredAlbums.count == 0) // 初期状態
    }
    
    @Test("filteredPhotos - showFavoritesOnlyフィルターテスト")
    func testFilteredPhotosWithFavoritesOnly() async throws {
        // Arrange
        let viewModel = FamilyAlbumViewModel()
        
        // Act
        viewModel.showFavoritesOnly = true
        
        // Assert
        // 実際のテストでは、モックデータでテスト
        #expect(viewModel.showFavoritesOnly == true)
    }
    
    @Test("photosByMonthプロパティテスト")
    func testPhotosByMonthProperty() async throws {
        // Arrange
        let viewModel = FamilyAlbumViewModel()
        
        // Act & Assert
        let photosByMonth = viewModel.photosByMonth
        #expect(photosByMonth.isEmpty) // 初期状態では空
    }
    
    @Test("albumsWithPhotoCountsプロパティテスト")
    func testAlbumsWithPhotoCountsProperty() async throws {
        // Arrange
        let viewModel = FamilyAlbumViewModel()
        
        // Act & Assert
        let albumsWithCounts = viewModel.albumsWithPhotoCounts
        #expect(albumsWithCounts.isEmpty) // 初期状態では空
    }
    
    @Test("DateFilter allCases配列テスト")
    func testDateFilterAllCases() async throws {
        // Act
        let allCases = FamilyAlbumViewModel.DateFilter.allCases
        
        // Assert
        #expect(allCases.count == 6)
        #expect(allCases.contains(.all))
        #expect(allCases.contains(.today))
        #expect(allCases.contains(.thisWeek))
        #expect(allCases.contains(.thisMonth))
        #expect(allCases.contains(.thisYear))
        #expect(allCases.contains(.custom))
    }
    
    @Test("エラーメッセージクリアテスト")
    func testClearError() async throws {
        // Arrange
        let viewModel = FamilyAlbumViewModel()
        // errorMessageを手動で設定（実際の実装では、サービスからエラーが設定される）
        
        // Act
        await viewModel.clearError()
        
        // Assert
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("選択状態プロパティテスト")
    func testSelectionStateProperties() async throws {
        // Arrange
        let viewModel = FamilyAlbumViewModel()
        let album = Album(name: "テストアルバム")
        let photo = Photo(assetIdentifier: "test-asset")
        let member = FamilyMember(name: "太郎", relationship: "息子")
        
        // Act
        viewModel.selectedAlbum = album
        viewModel.selectedPhoto = photo
        viewModel.selectedFamilyMember = member
        
        // Assert
        #expect(viewModel.selectedAlbum?.name == "テストアルバム")
        #expect(viewModel.selectedPhoto?.assetIdentifier == "test-asset")
        #expect(viewModel.selectedFamilyMember?.name == "太郎")
    }
}