import Foundation

// MARK: - StoryPreviewViewModel

/// スライドショープレビュー画面のViewModel
/// 再生/一時停止/ページ遷移を管理
@MainActor
@Observable
public final class StoryPreviewViewModel {
    // MARK: - Properties

    public var story: PhotoStory
    public var currentPageIndex: Int = 0
    public var isPlaying: Bool = false
    public var progress: Double = 0

    private var playbackTask: Task<Void, Never>?

    // MARK: - Computed Properties

    /// 現在のページ
    public var currentPage: StoryPage? {
        let sorted = story.sortedPages
        guard currentPageIndex >= 0, currentPageIndex < sorted.count else { return nil }
        return sorted[currentPageIndex]
    }

    /// ページ数
    public var pageCount: Int {
        story.pageCount
    }

    /// 最後のページかどうか
    public var isLastPage: Bool {
        currentPageIndex >= pageCount - 1
    }

    // MARK: - Init

    public init(story: PhotoStory) {
        self.story = story
    }

    // MARK: - 再生制御

    /// 再生開始
    public func play() {
        isPlaying = true
        startPlayback()
    }

    /// 一時停止
    public func pause() {
        isPlaying = false
        playbackTask?.cancel()
        playbackTask = nil
    }

    /// 次のページへ
    public func nextPage() {
        guard currentPageIndex < pageCount - 1 else {
            pause()
            return
        }
        currentPageIndex += 1
        updateProgress()
    }

    /// 前のページへ
    public func previousPage() {
        guard currentPageIndex > 0 else { return }
        currentPageIndex -= 1
        updateProgress()
    }

    /// 指定ページへ移動
    public func goToPage(_ index: Int) {
        guard index >= 0, index < pageCount else { return }
        currentPageIndex = index
        updateProgress()
    }

    /// 先頭に戻る
    public func reset() {
        pause()
        currentPageIndex = 0
        progress = 0
    }

    // MARK: - Private Methods

    private func startPlayback() {
        playbackTask?.cancel()
        playbackTask = Task { [weak self] in
            guard let self else { return }

            while self.isPlaying, self.currentPageIndex < self.pageCount {
                let duration = self.currentPage?.duration ?? 3.0
                let sleepNanoseconds = UInt64(duration * 1_000_000_000)

                do {
                    try await Task.sleep(nanoseconds: sleepNanoseconds)
                } catch {
                    return
                }

                guard !Task.isCancelled else { return }

                if self.currentPageIndex < self.pageCount - 1 {
                    self.currentPageIndex += 1
                    self.updateProgress()
                } else {
                    self.pause()
                }
            }
        }
    }

    private func updateProgress() {
        guard pageCount > 0 else {
            progress = 0
            return
        }
        progress = Double(currentPageIndex + 1) / Double(pageCount)
    }
}
