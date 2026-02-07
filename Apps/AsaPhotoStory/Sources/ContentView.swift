import SwiftUI
import AsaUIKit

/// メインコンテンツビュー
/// NavigationStackでStoryListViewをルートとして表示
struct ContentView: View {
    var body: some View {
        NavigationStack {
            StoryListView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [], inMemory: true)
}
