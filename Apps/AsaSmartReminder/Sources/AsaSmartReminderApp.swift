import AsaSmartReminderKit
import SwiftData
import SwiftUI

@main
struct AsaSmartReminderApp: App {
    private let dataService = ReminderDataService()

    var body: some Scene {
        WindowGroup {
            ContentView(dataService: dataService)
        }
        .modelContainer(dataService.modelContainer)
    }
}
