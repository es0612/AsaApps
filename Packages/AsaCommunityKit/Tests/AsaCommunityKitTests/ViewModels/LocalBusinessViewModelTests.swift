import Testing
import Foundation

@testable import AsaCommunityKit

@Suite("LocalBusinessViewModel テスト")
struct LocalBusinessViewModelTests {
    @MainActor
    @Test("店舗を正しく読み込む")
    func testLoadBusinesses() {
        let mock = MockCommunityDataService()
        mock.businesses = [
            LocalBusiness(name: "カフェ朝日", address: "1-2-3"),
            LocalBusiness(name: "薬局あさひ", category: .medical, address: "4-5-6"),
        ]
        let vm = LocalBusinessViewModel(dataService: mock)
        vm.loadBusinesses()

        #expect(vm.businesses.count == 2)
    }

    @MainActor
    @Test("カテゴリフィルタが正しく動作する")
    func testCategoryFilter() {
        let mock = MockCommunityDataService()
        mock.businesses = [
            LocalBusiness(name: "カフェ", category: .restaurant, address: "住所"),
            LocalBusiness(name: "薬局", category: .medical, address: "住所"),
        ]
        let vm = LocalBusinessViewModel(dataService: mock)
        vm.loadBusinesses()
        vm.selectedCategory = .restaurant

        #expect(vm.filteredBusinesses.count == 1)
        #expect(vm.filteredBusinesses.first?.name == "カフェ")
    }

    @MainActor
    @Test("お気に入りフィルタが動作する")
    func testFavoritesFilter() {
        let mock = MockCommunityDataService()
        let favBusiness = LocalBusiness(name: "お気に入り", address: "住所")
        favBusiness.isFavorite = true
        mock.businesses = [
            favBusiness,
            LocalBusiness(name: "普通のお店", address: "住所"),
        ]
        let vm = LocalBusinessViewModel(dataService: mock)
        vm.loadBusinesses()
        vm.showFavoritesOnly = true

        #expect(vm.filteredBusinesses.count == 1)
        #expect(vm.filteredBusinesses.first?.name == "お気に入り")
    }

    @MainActor
    @Test("検索フィルタが動作する")
    func testSearchFilter() {
        let mock = MockCommunityDataService()
        mock.businesses = [
            LocalBusiness(name: "朝日カフェ", address: "住所"),
            LocalBusiness(name: "夕日ベーカリー", address: "住所"),
        ]
        let vm = LocalBusinessViewModel(dataService: mock)
        vm.loadBusinesses()
        vm.searchText = "朝日"

        #expect(vm.filteredBusinesses.count == 1)
    }

    @MainActor
    @Test("お気に入り切り替えが動作する")
    func testToggleFavorite() {
        let mock = MockCommunityDataService()
        let business = LocalBusiness(name: "テスト", address: "住所")
        mock.businesses = [business]
        let vm = LocalBusinessViewModel(dataService: mock)
        vm.loadBusinesses()

        #expect(business.isFavorite == false)
        vm.toggleFavorite(business)
        #expect(business.isFavorite == true)
    }
}
