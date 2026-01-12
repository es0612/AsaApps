import SwiftUI

@main
struct AsaSocialFeedApp: App {
    @State private var viewModel: FeedViewModel

    init() {
        do {
            let dataService = try SocialFeedDataService()
            _viewModel = State(initialValue: FeedViewModel(dataService: dataService))
        } catch {
            fatalError("データサービス初期化エラー: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
