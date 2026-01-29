import SwiftUI
import SwiftData

@main
struct AsaBudgetAIApp: App {

    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try DataService.createContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // 通知カテゴリをセットアップ
        NotificationService.shared.setupNotificationCategories()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
