import SwiftUI

@main
struct AsaARCardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ARCardViewModel())
        }
    }
}