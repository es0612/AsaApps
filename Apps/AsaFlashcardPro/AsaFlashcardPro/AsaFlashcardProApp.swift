import SwiftUI
import SwiftData

@main
struct AsaFlashcardProApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Category.self, Flashcard.self, StudyProgress.self])
                .onAppear {
                    setupInitialData()
                }
        }
    }
    
    private func setupInitialData() {
        // 初回起動時にサンプルデータを作成する処理はContentViewで行う
    }
}