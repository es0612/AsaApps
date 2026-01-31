//
//  ContentView.swift
//  AsaLanguageLearn
//
//  メインコンテンツビュー
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Course.self,
            Lesson.self,
            LearningItem.self,
            LearningProgress.self,
            StudySession.self,
            UserProfile.self,
        ])
}
