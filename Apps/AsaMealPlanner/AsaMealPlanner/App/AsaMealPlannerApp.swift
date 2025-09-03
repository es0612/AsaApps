import SwiftUI
import SwiftData

@main
struct AsaMealPlannerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WeeklyPlan.self, Meal.self, Ingredient.self])
    }
}

// MARK: - Preview Support
#Preview {
    ContentView()
        .modelContainer(previewContainer)
}

// MARK: - Preview Data Container
@MainActor
let previewContainer: ModelContainer = {
    do {
        let container = try ModelContainer(
            for: WeeklyPlan.self, Meal.self, Ingredient.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        
        // サンプルデータを追加
        let samplePlan = WeeklyPlan.sampleData
        container.mainContext.insert(samplePlan)
        
        return container
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }
}()