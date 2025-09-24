import SwiftUI
import SwiftData

@main
struct AsaSmartTodoApp: App {
    @StateObject private var viewModel = SmartTodoViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .modelContainer(sharedModelContainer)
        }
    }
}

// MARK: - Model Container

var sharedModelContainer: ModelContainer = {
    let schema = Schema([
        SmartTask.self,
        TaskAnalytics.self
    ])

    let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false
    )

    do {
        return try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()