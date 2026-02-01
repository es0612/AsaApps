import SwiftUI
import SwiftData
import AsaFamilyTreeKit

@main
struct AsaFamilyTreeApp: App {
    // MARK: - Properties

    @State private var viewModel = FamilyTreeViewModel()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
        .modelContainer(for: [FamilyTree.self, FamilyMember.self, Marriage.self]) { result in
            switch result {
            case .success(let container):
                viewModel.configure(with: container.mainContext)
            case .failure(let error):
                print("SwiftData初期化エラー: \(error.localizedDescription)")
            }
        }
    }
}
