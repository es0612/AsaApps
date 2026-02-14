import Testing
import Foundation
@testable import AsaLifeLogKit

// MARK: - TimelineViewModel Tests

@Suite("TimelineViewModel", .tags(.viewModel))
@MainActor
struct TimelineViewModelTests {
    @Test("初期状態が正しい")
    func initialState() {
        let vm = TimelineViewModel(
            dataService: MockDataService(),
            timelineService: TimelineService()
        )
        #expect(vm.entries.isEmpty)
        #expect(vm.selectedSource == nil)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @Test("loadEntries がエントリーを読み込む")
    func loadEntries() async {
        let mockDataService = MockDataService()
        let entry = LifeLogEntry(entryType: .manual, title: "テスト")
        mockDataService.entries = [entry]

        let vm = TimelineViewModel(
            dataService: mockDataService,
            timelineService: TimelineService()
        )
        await vm.loadEntries()

        #expect(!vm.entries.isEmpty)
        #expect(vm.isLoading == false)
    }

    @Test("filterBySource がソースを設定する")
    func filterBySource() {
        let vm = TimelineViewModel(
            dataService: MockDataService(),
            timelineService: TimelineService()
        )
        vm.filterBySource(.healthKit)
        #expect(vm.selectedSource == .healthKit)

        vm.filterBySource(nil)
        #expect(vm.selectedSource == nil)
    }

    @Test("filteredEntries がソースでフィルタする")
    func filteredEntries() async {
        let mockDataService = MockDataService()
        let manualEntry = LifeLogEntry(entryType: .manual, title: "手動", source: .manual)
        let healthEntry = LifeLogEntry(entryType: .health, title: "健康", source: .healthKit)
        mockDataService.entries = [manualEntry, healthEntry]

        let vm = TimelineViewModel(
            dataService: mockDataService,
            timelineService: TimelineService()
        )
        await vm.loadEntries()

        // フィルタなし → 全件
        #expect(vm.filteredEntries.count == 2)

        // HealthKit でフィルタ
        vm.filterBySource(.healthKit)
        #expect(vm.filteredEntries.count == 1)
        #expect(vm.filteredEntries.first?.source == .healthKit)
    }

    @Test("toggleFavorite がお気に入りを切り替える")
    func toggleFavorite() async {
        let mockDataService = MockDataService()
        let entry = LifeLogEntry(entryType: .manual, title: "テスト")
        #expect(entry.isFavorite == false)

        let vm = TimelineViewModel(
            dataService: mockDataService,
            timelineService: TimelineService()
        )
        await vm.toggleFavorite(entry)
        #expect(mockDataService.toggleFavoriteCalled == true)
    }

    @Test("deleteEntry がエントリーを削除する")
    func deleteEntry() async {
        let mockDataService = MockDataService()
        let entry = LifeLogEntry(entryType: .manual, title: "削除テスト")
        mockDataService.entries = [entry]

        let vm = TimelineViewModel(
            dataService: mockDataService,
            timelineService: TimelineService()
        )
        await vm.loadEntries()
        #expect(vm.entries.count == 1)

        await vm.deleteEntry(entry)
        #expect(vm.entries.isEmpty)
        #expect(mockDataService.deleteEntryCalled == true)
    }

    @Test("エラー時に errorMessage が設定される")
    func errorHandling() async {
        let mockDataService = MockDataService()
        mockDataService.shouldThrowError = true

        let vm = TimelineViewModel(
            dataService: mockDataService,
            timelineService: TimelineService()
        )
        await vm.loadEntries()
        #expect(vm.errorMessage != nil)
        #expect(vm.isLoading == false)
    }
}

// MARK: - EntryEditorViewModel Tests

@Suite("EntryEditorViewModel", .tags(.viewModel))
@MainActor
struct EntryEditorViewModelTests {
    @Test("初期状態が正しい")
    func initialState() {
        let vm = EntryEditorViewModel(dataService: MockDataService())
        #expect(vm.title == "")
        #expect(vm.content == "")
        #expect(vm.entryType == .manual)
        #expect(vm.moodScore == nil)
        #expect(vm.tags.isEmpty)
        #expect(vm.isSaving == false)
    }

    @Test("loadEntry が既存エントリーの値をロードする")
    func loadEntry() {
        let vm = EntryEditorViewModel(dataService: MockDataService())
        let entry = LifeLogEntry(
            entryType: .mood,
            title: "既存記録",
            content: "テスト内容",
            moodScore: .great,
            tags: ["朝活"],
            locationName: "東京駅"
        )
        vm.loadEntry(entry)
        #expect(vm.title == "既存記録")
        #expect(vm.content == "テスト内容")
        #expect(vm.entryType == .mood)
        #expect(vm.moodScore == .great)
        #expect(vm.tags == ["朝活"])
        #expect(vm.locationName == "東京駅")
    }

    @Test("空のタイトルで保存しようとするとエラーになる")
    func saveWithEmptyTitle() async {
        let vm = EntryEditorViewModel(dataService: MockDataService())
        vm.title = "   "
        let result = await vm.saveEntry()
        #expect(result == false)
        #expect(vm.errorMessage == "タイトルを入力してください")
    }

    @Test("有効なタイトルで保存に成功する")
    func saveWithValidTitle() async {
        let mockDataService = MockDataService()
        let vm = EntryEditorViewModel(dataService: mockDataService)
        vm.title = "新しい記録"
        vm.moodScore = .good

        let result = await vm.saveEntry()
        #expect(result == true)
        #expect(mockDataService.saveEntryCalled == true)
    }

    @Test("タグの追加と削除が正しく動作する")
    func tagManagement() {
        let vm = EntryEditorViewModel(dataService: MockDataService())

        vm.addTag("朝活")
        #expect(vm.tags == ["朝活"])

        vm.addTag("運動")
        #expect(vm.tags == ["朝活", "運動"])

        // 重複は追加されない
        vm.addTag("朝活")
        #expect(vm.tags.count == 2)

        // 空文字は追加されない
        vm.addTag("  ")
        #expect(vm.tags.count == 2)

        vm.removeTag("朝活")
        #expect(vm.tags == ["運動"])
    }

    @Test("resetForm がフォームをリセットする")
    func resetForm() {
        let vm = EntryEditorViewModel(dataService: MockDataService())
        vm.title = "テスト"
        vm.content = "内容"
        vm.moodScore = .great
        vm.tags = ["tag1"]
        vm.latitude = 35.0

        vm.resetForm()
        #expect(vm.title == "")
        #expect(vm.content == "")
        #expect(vm.moodScore == nil)
        #expect(vm.tags.isEmpty)
        #expect(vm.latitude == nil)
    }

    @Test("setCurrentLocation で位置情報が設定される")
    func setCurrentLocation() async {
        let mockLocation = MockLocationService()
        mockLocation.currentLocation = (latitude: 35.6762, longitude: 139.6503)
        mockLocation.reverseGeocodeResult = "東京都 千代田区"

        let vm = EntryEditorViewModel(
            dataService: MockDataService(),
            locationService: mockLocation
        )
        await vm.setCurrentLocation()
        #expect(vm.latitude == 35.6762)
        #expect(vm.longitude == 139.6503)
        #expect(vm.locationName == "東京都 千代田区")
    }

    @Test("位置情報サービスがない場合はエラーメッセージが設定される")
    func setLocationWithoutService() async {
        let vm = EntryEditorViewModel(dataService: MockDataService())
        await vm.setCurrentLocation()
        #expect(vm.errorMessage == "位置情報サービスが利用できません")
    }
}

// MARK: - DashboardViewModel Tests

@Suite("DashboardViewModel", .tags(.viewModel))
@MainActor
struct DashboardViewModelTests {
    @Test("初期状態が正しい")
    func initialState() {
        let vm = DashboardViewModel(
            dataService: MockDataService(),
            insightsEngine: MockInsightsEngine()
        )
        #expect(vm.dailySummary == nil)
        #expect(vm.morningScore == 0)
        #expect(vm.selectedPeriod == .week)
        #expect(vm.isLoading == false)
    }

    @Test("loadDashboardData がデータを読み込む")
    func loadDashboardData() async {
        let mockDataService = MockDataService()
        let mockEngine = MockInsightsEngine()
        mockEngine.morningScoreResult = 75

        let entry = LifeLogEntry(entryType: .mood, title: "気分", moodScore: .good)
        mockDataService.entries = [entry]

        let vm = DashboardViewModel(
            dataService: mockDataService,
            insightsEngine: mockEngine
        )
        await vm.loadDashboardData()

        #expect(vm.morningScore == 75)
        #expect(vm.isLoading == false)
    }

    @Test("changePeriod が期間を変更してリロードする")
    func changePeriod() async {
        let vm = DashboardViewModel(
            dataService: MockDataService(),
            insightsEngine: MockInsightsEngine()
        )
        await vm.changePeriod(.month)
        #expect(vm.selectedPeriod == .month)
    }

    @Test("エラー時に errorMessage が設定される")
    func errorHandling() async {
        let mockDataService = MockDataService()
        mockDataService.shouldThrowError = true

        let vm = DashboardViewModel(
            dataService: mockDataService,
            insightsEngine: MockInsightsEngine()
        )
        await vm.loadDashboardData()
        #expect(vm.errorMessage != nil)
    }
}

// MARK: - InsightsViewModel Tests

@Suite("InsightsViewModel", .tags(.viewModel))
@MainActor
struct InsightsViewModelTests {
    @Test("初期状態が正しい")
    func initialState() {
        let vm = InsightsViewModel(
            dataService: MockDataService(),
            insightsEngine: MockInsightsEngine()
        )
        #expect(vm.dailyInsight == nil)
        #expect(vm.weeklyInsight == nil)
        #expect(vm.patterns.isEmpty)
        #expect(vm.morningScore == 0)
    }

    @Test("generateTodayInsights が日次インサイトを生成する")
    func generateTodayInsights() async {
        let mockEngine = MockInsightsEngine()
        mockEngine.morningScoreResult = 80

        let vm = InsightsViewModel(
            dataService: MockDataService(),
            insightsEngine: mockEngine
        )
        await vm.generateTodayInsights()

        #expect(vm.dailyInsight != nil)
        #expect(vm.morningScore == 80)
        #expect(vm.isLoading == false)
    }

    @Test("generateWeeklyInsights が週次インサイトを生成する")
    func generateWeeklyInsights() async {
        let vm = InsightsViewModel(
            dataService: MockDataService(),
            insightsEngine: MockInsightsEngine()
        )
        await vm.generateWeeklyInsights()
        #expect(vm.weeklyInsight != nil)
    }

    @Test("detectPatterns がパターンを検出する")
    func detectPatterns() async {
        let mockEngine = MockInsightsEngine()
        mockEngine.patternsResult = [
            PatternResult(patternType: "test", description: "テストパターン", confidence: 0.8),
        ]

        let vm = InsightsViewModel(
            dataService: MockDataService(),
            insightsEngine: mockEngine
        )
        await vm.detectPatterns()
        #expect(vm.patterns.count == 1)
    }

    @Test("エラー時に errorMessage が設定される")
    func errorHandling() async {
        let mockDataService = MockDataService()
        mockDataService.shouldThrowError = true

        let vm = InsightsViewModel(
            dataService: mockDataService,
            insightsEngine: MockInsightsEngine()
        )
        await vm.generateTodayInsights()
        #expect(vm.errorMessage != nil)
    }
}

// MARK: - SettingsViewModel Tests

@Suite("SettingsViewModel", .tags(.viewModel))
@MainActor
struct SettingsViewModelTests {
    @Test("初期状態が正しい")
    func initialState() {
        let vm = SettingsViewModel(dataService: MockDataService())
        #expect(vm.preferences == nil)
        #expect(vm.isLoading == false)
        #expect(vm.exportedData == nil)
    }

    @Test("loadPreferences が設定を読み込む")
    func loadPreferences() async {
        let vm = SettingsViewModel(dataService: MockDataService())
        await vm.loadPreferences()
        #expect(vm.preferences != nil)
        #expect(vm.preferences?.enableHealthTracking == true)
    }

    @Test("toggleHealthTracking がトグルして保存する")
    func toggleHealthTracking() async {
        let mockDataService = MockDataService()
        let vm = SettingsViewModel(dataService: mockDataService)
        await vm.loadPreferences()

        let initial = vm.preferences?.enableHealthTracking ?? true
        await vm.toggleHealthTracking()
        #expect(vm.preferences?.enableHealthTracking == !initial)
        #expect(mockDataService.savePreferencesCalled == true)
    }

    @Test("exportDataAsJSON がデータをエクスポートする")
    func exportJSON() async {
        let mockDataService = MockDataService()
        let entry = LifeLogEntry(entryType: .manual, title: "エクスポートテスト")
        mockDataService.entries = [entry]

        let vm = SettingsViewModel(dataService: mockDataService)
        await vm.exportDataAsJSON()
        #expect(vm.exportedData != nil)
    }

    @Test("exportDataAsCSV がデータをエクスポートする")
    func exportCSV() async {
        let mockDataService = MockDataService()
        let entry = LifeLogEntry(entryType: .manual, title: "CSVテスト")
        mockDataService.entries = [entry]

        let vm = SettingsViewModel(dataService: mockDataService)
        await vm.exportDataAsCSV()
        #expect(vm.exportedData != nil)
    }

    @Test("エラー時に errorMessage が設定される")
    func errorHandling() async {
        let mockDataService = MockDataService()
        mockDataService.shouldThrowError = true

        let vm = SettingsViewModel(dataService: mockDataService)
        await vm.loadPreferences()
        #expect(vm.errorMessage != nil)
    }
}

// MARK: - PlaceLogViewModel Tests

@Suite("PlaceLogViewModel", .tags(.viewModel))
@MainActor
struct PlaceLogViewModelTests {
    @Test("初期状態が正しい")
    func initialState() {
        let vm = PlaceLogViewModel(dataService: MockDataService())
        #expect(vm.places.isEmpty)
        #expect(vm.selectedPlace == nil)
        #expect(vm.isLoading == false)
    }

    @Test("loadPlaces が場所を読み込む")
    func loadPlaces() async {
        let mockDataService = MockDataService()
        mockDataService.places = [
            PlaceLog(name: "スタバ", category: .restaurant),
            PlaceLog(name: "自宅", category: .home),
        ]

        let vm = PlaceLogViewModel(dataService: mockDataService)
        await vm.loadPlaces()
        #expect(vm.places.count == 2)
    }

    @Test("favoritePlaces がお気に入りのみ返す")
    func favoritePlaces() async {
        let mockDataService = MockDataService()
        let fav = PlaceLog(name: "お気に入り", isFavorite: true)
        let normal = PlaceLog(name: "通常")
        mockDataService.places = [fav, normal]

        let vm = PlaceLogViewModel(dataService: mockDataService)
        await vm.loadPlaces()
        #expect(vm.favoritePlaces.count == 1)
        #expect(vm.favoritePlaces.first?.name == "お気に入り")
    }

    @Test("placesByCategory がカテゴリ別にグループ化する")
    func placesByCategory() async {
        let mockDataService = MockDataService()
        mockDataService.places = [
            PlaceLog(name: "自宅", category: .home),
            PlaceLog(name: "スタバ", category: .restaurant),
            PlaceLog(name: "マック", category: .restaurant),
        ]

        let vm = PlaceLogViewModel(dataService: mockDataService)
        await vm.loadPlaces()
        #expect(vm.placesByCategory[.home]?.count == 1)
        #expect(vm.placesByCategory[.restaurant]?.count == 2)
    }

    @Test("toggleFavorite がお気に入りを切り替える")
    func toggleFavorite() async {
        let mockDataService = MockDataService()
        let place = PlaceLog(name: "テスト場所")
        #expect(place.isFavorite == false)

        let vm = PlaceLogViewModel(dataService: mockDataService)
        await vm.toggleFavorite(place)
        #expect(place.isFavorite == true)
        #expect(mockDataService.savePlaceLogCalled == true)
    }

    @Test("toggleFavorite エラー時にロールバックする")
    func toggleFavoriteRollback() async {
        let mockDataService = MockDataService()
        mockDataService.shouldThrowError = true
        let place = PlaceLog(name: "テスト")
        place.isFavorite = false

        let vm = PlaceLogViewModel(dataService: mockDataService)
        await vm.toggleFavorite(place)
        // エラー時はロールバックされる
        #expect(place.isFavorite == false)
        #expect(vm.errorMessage != nil)
    }

    @Test("selectPlace が場所を選択する")
    func selectPlace() {
        let vm = PlaceLogViewModel(dataService: MockDataService())
        let place = PlaceLog(name: "選択テスト")
        vm.selectPlace(place)
        #expect(vm.selectedPlace?.name == "選択テスト")
    }

    @Test("clearSelection が選択を解除する")
    func clearSelection() {
        let vm = PlaceLogViewModel(dataService: MockDataService())
        vm.selectPlace(PlaceLog(name: "テスト"))
        vm.clearSelection()
        #expect(vm.selectedPlace == nil)
    }

    @Test("エラー時に errorMessage が設定される")
    func errorHandling() async {
        let mockDataService = MockDataService()
        mockDataService.shouldThrowError = true

        let vm = PlaceLogViewModel(dataService: mockDataService)
        await vm.loadPlaces()
        #expect(vm.errorMessage != nil)
    }
}

// MARK: - Tags

extension Tag {
    @Tag static var viewModel: Self
}
