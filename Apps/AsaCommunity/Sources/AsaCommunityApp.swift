import SwiftUI
import SwiftData
import AsaCommunityKit
import TipKit

@main
struct AsaCommunityApp: App {
    init() {
        try? Tips.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Community.self,
            CommunityProfile.self,
            CommunityPost.self,
            CommunityEvent.self,
            EventRSVP.self,
            SafetyReport.self,
            EvacuationShelter.self,
            GarbageSchedule.self,
            LocalBusiness.self,
            CommunitySettings.self,
        ])
    }
}
