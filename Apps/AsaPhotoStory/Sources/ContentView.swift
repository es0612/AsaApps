import SwiftUI
import SwiftData
import AsaUIKit
import AsaPhotoStoryKit

/// メインコンテンツビュー
/// NavigationStackでStoryListViewをルートとして表示
struct ContentView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Body

    var body: some View {
        NavigationStack {
            StoryListView()
        }
        .task {
            await loadSampleDataIfNeeded()
        }
    }

    // MARK: - Sample Data Loading

    /// 初回起動時にデモ用サンプルデータを投入
    private func loadSampleDataIfNeeded() async {
        let key = "AsaPhotoStory_SampleDataLoaded_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let service = SampleDataService(modelContext: modelContext)
        do {
            try service.loadSampleData()
            UserDefaults.standard.set(true, forKey: key)
        } catch {
            print("サンプルデータ投入エラー: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [], inMemory: true)
}
