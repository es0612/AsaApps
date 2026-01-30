import SwiftUI
import AsaUIKit

// MARK: - ContentView

struct ContentView: View {
    // MARK: - Properties

    @Environment(AuthViewModel.self) private var authViewModel
    @State private var networkMonitor = NetworkMonitor()

    // MARK: - Body

    var body: some View {
        ZStack {
            switch authViewModel.state {
            case .loading:
                loadingView

            case .signedOut:
                AuthView()

            case .signedIn(let user):
                EventListView(user: user)
            }

            // オフラインバナー
            if !networkMonitor.isConnected {
                offlineBanner
            }
        }
        .environment(networkMonitor)
    }

    // MARK: - Subviews

    private var loadingView: some View {
        ZStack {
            AsaColors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(AsaColors.coffeeBrown)

                Text("読み込み中...")
                    .font(.subheadline)
                    .foregroundStyle(AsaColors.mutedSage)
            }
        }
    }

    private var offlineBanner: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                Text("オフラインモード")
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AsaColors.mocha.opacity(0.9))
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .shadow(radius: 2)

            Spacer()
        }
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut, value: networkMonitor.isConnected)
    }
}

// MARK: - Preview

#Preview {
    let dataService = MockEventDataService()
    let authViewModel = AuthViewModel(dataService: dataService)

    return ContentView()
        .environment(authViewModel)
}
