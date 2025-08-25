import SwiftUI
import SwiftData
import AsaTaskKit

@main
struct AsaTaskBoardApp: App {
    
    private let dataService: TaskDataService
    
    init() {
        do {
            self.dataService = try TaskDataService()
        } catch {
            fatalError("Failed to initialize TaskDataService: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(TaskBoardViewModel(dataService: dataService))
                .modelContainer(dataService.modelContext.container)
        }
    }
}