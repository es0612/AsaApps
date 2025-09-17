import SwiftUI

@main
struct AsaTimeZoneApp: App {
    @State private var viewModel = TimeZoneViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
    }
}