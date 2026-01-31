//
//  AsaLanguageLearnApp.swift
//  AsaLanguageLearn
//
//  音声認識・音声合成・間隔反復学習を組み合わせた英語学習アプリ
//

import SwiftData
import SwiftUI

@main
struct AsaLanguageLearnApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Course.self,
            Lesson.self,
            LearningItem.self,
            LearningProgress.self,
            StudySession.self,
            UserProfile.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
