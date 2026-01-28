import SwiftUI
import SwiftData

@main
struct AsaStudyPlannerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            StudyItem.self,
            StudySession.self,
            StudyPlan.self,
            LearningAnalytics.self,
            UserLearningProfile.self
        ])
    }
}
