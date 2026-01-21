import SwiftUI

// MARK: - AsaARGameApp
@main
struct AsaARGameApp: App {
    @State private var viewModel = ARGameViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
    }
}
