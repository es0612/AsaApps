import SwiftUI
import SwiftData
import AsaFinancePlannerKit

@main
struct AsaFinancePlannerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            FinancialPlan.self,
            FinancialGoal.self,
            Asset.self,
            Contribution.self,
            Scenario.self,
            UserSettings.self,
        ])
    }
}
