import SwiftUI

@main
struct AsaTimeZoneApp: App {
    @StateObject private var viewModel = TimeZoneViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}