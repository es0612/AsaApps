import SwiftUI
import SwiftData

@main
struct AsaECommerceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Order.self)
    }
}
