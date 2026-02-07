import SwiftUI
import SwiftData
import AsaPhotoStoryKit

/// AsaPhotoStory - 写真ストーリー作成アプリ
/// 家族の思い出を美しいフォトストーリーに変換するアプリ
@main
struct AsaPhotoStoryApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            PhotoStory.self,
            StoryPage.self,
            StoryElement.self,
        ])
    }
}
