import Foundation
import Testing
@testable import AsaSmartReminderKit

// MARK: - ReminderDataService テスト

@Suite("ReminderDataService")
@MainActor
struct ReminderDataServiceTests {

    // MARK: - ヘルパー

    private func makeService() -> ReminderDataService {
        ReminderDataService(inMemory: true)
    }

    private func makeSampleLocation(
        name: String = "テスト場所",
        category: LocationCategory = .custom
    ) -> ReminderLocation {
        ReminderLocation(
            name: name,
            latitude: 35.6812,
            longitude: 139.7671,
            radius: 100,
            category: category
        )
    }

    private func makeSampleReminder(
        title: String = "テストリマインダー",
        location: ReminderLocation? = nil
    ) -> LocationReminder {
        LocationReminder(
            title: title,
            location: location
        )
    }

    // MARK: - 場所 CRUD

    @Test("場所を保存して取得できる")
    func saveAndFetchLocation() throws {
        let service = makeService()
        let location = makeSampleLocation()
        try service.saveLocation(location)
        let fetched = try service.fetchAllLocations()
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "テスト場所")
    }

    @Test("複数場所を保存して全件取得")
    func fetchMultipleLocations() throws {
        let service = makeService()
        try service.saveLocation(makeSampleLocation(name: "場所1"))
        try service.saveLocation(makeSampleLocation(name: "場所2"))
        try service.saveLocation(makeSampleLocation(name: "場所3"))
        let fetched = try service.fetchAllLocations()
        #expect(fetched.count == 3)
    }

    @Test("カテゴリでフィルタ取得")
    func fetchLocationsByCategory() throws {
        let service = makeService()
        try service.saveLocation(makeSampleLocation(name: "自宅", category: .home))
        try service.saveLocation(makeSampleLocation(name: "職場", category: .work))
        try service.saveLocation(makeSampleLocation(name: "学校", category: .school))

        let homeLocations = try service.fetchLocations(category: .home)
        #expect(homeLocations.count == 1)
        #expect(homeLocations.first?.name == "自宅")
    }

    @Test("IDで場所を取得")
    func fetchLocationById() throws {
        let service = makeService()
        let location = makeSampleLocation()
        try service.saveLocation(location)
        let fetched = try service.fetchLocation(id: location.id)
        #expect(fetched?.name == "テスト場所")
    }

    @Test("存在しないIDではnilを返す")
    func fetchNonexistentLocation() throws {
        let service = makeService()
        let fetched = try service.fetchLocation(id: UUID())
        #expect(fetched == nil)
    }

    @Test("場所を削除できる")
    func deleteLocation() throws {
        let service = makeService()
        let location = makeSampleLocation()
        try service.saveLocation(location)
        #expect(try service.fetchAllLocations().count == 1)
        try service.deleteLocation(location)
        #expect(try service.fetchAllLocations().count == 0)
    }

    // MARK: - リマインダー CRUD

    @Test("リマインダーを保存して取得できる")
    func saveAndFetchReminder() throws {
        let service = makeService()
        let reminder = makeSampleReminder()
        try service.saveReminder(reminder)
        let fetched = try service.fetchAllReminders()
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "テストリマインダー")
    }

    @Test("アクティブなリマインダーのみ取得")
    func fetchActiveReminders() throws {
        let service = makeService()
        let active = LocationReminder(title: "アクティブ", isActive: true)
        let completed = LocationReminder(title: "完了済み", isCompleted: true, isActive: false)
        let inactive = LocationReminder(title: "無効", isActive: false)
        try service.saveReminder(active)
        try service.saveReminder(completed)
        try service.saveReminder(inactive)

        let fetched = try service.fetchActiveReminders()
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "アクティブ")
    }

    @Test("完了したリマインダーのみ取得")
    func fetchCompletedReminders() throws {
        let service = makeService()
        let active = LocationReminder(title: "アクティブ")
        let completed = LocationReminder(title: "完了済み", isCompleted: true)
        try service.saveReminder(active)
        try service.saveReminder(completed)

        let fetched = try service.fetchCompletedReminders()
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "完了済み")
    }

    @Test("IDでリマインダーを取得")
    func fetchReminderById() throws {
        let service = makeService()
        let reminder = makeSampleReminder()
        try service.saveReminder(reminder)
        let fetched = try service.fetchReminder(id: reminder.id)
        #expect(fetched?.title == "テストリマインダー")
    }

    @Test("リマインダーを削除できる")
    func deleteReminder() throws {
        let service = makeService()
        let reminder = makeSampleReminder()
        try service.saveReminder(reminder)
        #expect(try service.fetchAllReminders().count == 1)
        try service.deleteReminder(reminder)
        #expect(try service.fetchAllReminders().count == 0)
    }

    @Test("リマインダーの更新がsaveで反映される")
    func updateReminder() throws {
        let service = makeService()
        let reminder = makeSampleReminder(title: "元のタイトル")
        try service.saveReminder(reminder)
        reminder.title = "更新後のタイトル"
        try service.save()

        let fetched = try service.fetchReminder(id: reminder.id)
        #expect(fetched?.title == "更新後のタイトル")
    }

    // MARK: - 設定

    @Test("設定が存在しない場合デフォルトが作成される")
    func getUserSettingsDefault() throws {
        let service = makeService()
        let settings = try service.getUserSettings()
        #expect(settings.defaultRadius == 100)
        #expect(settings.defaultTriggerOnEntry == true)
    }

    @Test("設定の更新が反映される")
    func updateSettings() throws {
        let service = makeService()
        let settings = try service.getUserSettings()
        settings.defaultRadius = 250
        try service.saveSettings(settings)
        let fetched = try service.getUserSettings()
        #expect(fetched.defaultRadius == 250)
    }

    // MARK: - 統計

    @Test("アクティブリマインダーなしで場所数0")
    func activeLocationCountZero() throws {
        let service = makeService()
        try service.saveLocation(makeSampleLocation())
        #expect(try service.activeLocationCount() == 0)
    }
}
