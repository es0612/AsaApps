import SwiftUI

@main
struct AsaARCardApp: App {
    @State private var viewModel = ARCardViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
    }
}