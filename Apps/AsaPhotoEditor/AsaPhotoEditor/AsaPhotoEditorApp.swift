import SwiftUI
import SwiftData

@main
struct AsaPhotoEditorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: EditProject.self)
    }
}
