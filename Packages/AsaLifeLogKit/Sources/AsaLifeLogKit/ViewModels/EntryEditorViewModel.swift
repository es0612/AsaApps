import Foundation

// MARK: - EntryEditorViewModel

/// エントリー編集のViewModel
///
/// 新規エントリーの作成・編集、タグ管理、位置情報設定を管理する。
@MainActor @Observable
public final class EntryEditorViewModel {
    // MARK: - Dependencies

    private let dataService: any LifeLogDataServiceProtocol
    private let locationService: (any LocationTrackingServiceProtocol)?

    // MARK: - Properties

    public var title: String = ""
    public var content: String = ""
    public var entryType: EntryType = .manual
    public var moodScore: MoodScore?
    public var tags: [String] = []
    public var latitude: Double?
    public var longitude: Double?
    public var locationName: String?
    public var photoIdentifiers: [String] = []
    public var isSaving: Bool = false
    public var errorMessage: String?

    /// 編集中のエントリー（既存エントリー編集時）
    private var editingEntry: LifeLogEntry?

    // MARK: - Init

    public init(
        dataService: any LifeLogDataServiceProtocol,
        locationService: (any LocationTrackingServiceProtocol)? = nil
    ) {
        self.dataService = dataService
        self.locationService = locationService
    }

    // MARK: - Methods

    /// 既存エントリーを編集対象としてロードする
    public func loadEntry(_ entry: LifeLogEntry) {
        editingEntry = entry
        title = entry.title
        content = entry.content ?? ""
        entryType = entry.entryType
        moodScore = entry.moodScore
        tags = entry.tags
        latitude = entry.latitude
        longitude = entry.longitude
        locationName = entry.locationName
        photoIdentifiers = entry.photoAssetIdentifiers
    }

    /// エントリーを保存する
    public func saveEntry() async -> Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "タイトルを入力してください"
            return false
        }

        isSaving = true
        errorMessage = nil

        do {
            if let existing = editingEntry {
                // 既存エントリーの更新
                existing.title = title
                existing.content = content.isEmpty ? nil : content
                existing.entryType = entryType
                existing.moodScore = moodScore
                existing.tags = tags
                existing.latitude = latitude
                existing.longitude = longitude
                existing.locationName = locationName
                existing.photoAssetIdentifiers = photoIdentifiers
                existing.updatedAt = Date()
                try await dataService.saveEntry(existing)
            } else {
                // 新規エントリーの作成
                let entry = LifeLogEntry(
                    entryType: entryType,
                    title: title,
                    content: content.isEmpty ? nil : content,
                    moodScore: moodScore,
                    tags: tags,
                    latitude: latitude,
                    longitude: longitude,
                    locationName: locationName,
                    photoAssetIdentifiers: photoIdentifiers,
                    source: .manual
                )
                try await dataService.saveEntry(entry)
            }
            isSaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
            return false
        }
    }

    /// タグを追加する
    public func addTag(_ tag: String) {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
    }

    /// タグを削除する
    public func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    /// 現在位置を設定する
    public func setCurrentLocation() async {
        guard let service = locationService else {
            errorMessage = "位置情報サービスが利用できません"
            return
        }

        if let location = service.currentLocation {
            latitude = location.latitude
            longitude = location.longitude
            do {
                locationName = try await service.reverseGeocode(
                    latitude: location.latitude,
                    longitude: location.longitude
                )
            } catch {
                locationName = nil
            }
        } else {
            errorMessage = "現在位置を取得できません"
        }
    }

    /// フォームをリセットする
    public func resetForm() {
        editingEntry = nil
        title = ""
        content = ""
        entryType = .manual
        moodScore = nil
        tags = []
        latitude = nil
        longitude = nil
        locationName = nil
        photoIdentifiers = []
        errorMessage = nil
    }
}
