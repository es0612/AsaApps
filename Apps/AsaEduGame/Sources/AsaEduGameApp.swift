import SwiftUI
import SwiftData
import AsaEduGameKit

// MARK: - AsaEduGame App

/// 子供向け教育ゲームアプリ（対象: 4-8歳）
/// 4つのゲームモード（算数・ひらがな・図形・論理）で楽しく学べる
@main
struct AsaEduGameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            UserProfile.self,
            GameSession.self,
            LearningRecord.self,
            Achievement.self
        ])
    }
}
