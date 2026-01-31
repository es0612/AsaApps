import SwiftUI
import SwiftData

// MARK: - AsaSmartHomeApp

/// AsaSmartHome - スマートホームコントロールアプリ
/// 模擬IoTデバイスを操作するシミュレーターベースのアプリ
@main
struct AsaSmartHomeApp: App {
    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            MainView()
                .modelContainer(for: [
                    SmartDevice.self,
                    Room.self,
                    SmartScene.self,
                    Schedule.self
                ])
        }
    }
}

// MARK: - MainView

/// メインビュー - ViewModelをMainActorで初期化
@MainActor
struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SmartHomeViewModel?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                ContentView(viewModel: viewModel)
            } else {
                loadingView
            }
        }
        .task {
            let service = MockSmartHomeService(modelContext: modelContext)
            viewModel = SmartHomeViewModel(service: service)
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        ZStack {
            Color.asaDarkSlate
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.asaCoffeeBrown.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "house.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.asaCoffeeBrown)
                }

                Text("読み込み中...")
                    .font(.headline)
                    .foregroundStyle(.white)

                ProgressView()
                    .tint(Color.asaCoffeeBrown)
                    .scaleEffect(1.2)
            }
        }
    }
}
