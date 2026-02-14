import Foundation

// MARK: - TimelineViewModel

/// タイムライン表示のViewModel
///
/// 日付ごとのエントリー一覧表示、ソースフィルタ、お気に入り切り替え、削除を管理する。
@MainActor @Observable
public final class TimelineViewModel {
    // MARK: - Dependencies

    private let dataService: any LifeLogDataServiceProtocol
    private let timelineService: any TimelineServiceProtocol

    // MARK: - Properties

    public var entries: [LifeLogEntry] = []
    public var selectedDate: Date = Date()
    public var selectedSource: DataSource?
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Init

    public init(
        dataService: any LifeLogDataServiceProtocol,
        timelineService: any TimelineServiceProtocol
    ) {
        self.dataService = dataService
        self.timelineService = timelineService
    }

    // MARK: - Computed Properties

    /// ソースでフィルタされたエントリー
    public var filteredEntries: [LifeLogEntry] {
        guard let source = selectedSource else { return entries }
        return entries.filter { $0.source == source }
    }

    // MARK: - Methods

    /// 選択日のエントリーを読み込む
    public func loadEntries() async {
        isLoading = true
        errorMessage = nil
        do {
            entries = try await timelineService.buildTimeline(
                for: selectedDate,
                dataService: dataService
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// ソースでフィルタする
    public func filterBySource(_ source: DataSource?) {
        selectedSource = source
    }

    /// お気に入りを切り替える
    public func toggleFavorite(_ entry: LifeLogEntry) async {
        errorMessage = nil
        do {
            try await dataService.toggleFavorite(entry)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// エントリーを削除する
    public func deleteEntry(_ entry: LifeLogEntry) async {
        errorMessage = nil
        do {
            try await dataService.deleteEntry(entry)
            entries.removeAll { $0.id == entry.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
