import SwiftUI
import SwiftData
import AsaUIKit

struct ContentView: View {
    @State private var productViewModel = ProductViewModel()
    @State private var cartViewModel = CartViewModel()

    @State private var selectedTab = 0
    @State private var showingToast = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // 商品一覧タブ
                ProductListView(
                    productViewModel: productViewModel,
                    cartViewModel: cartViewModel
                )
                .tabItem {
                    Label("商品", systemImage: "bag")
                }
                .tag(0)

                // カートタブ
                CartView(cartViewModel: cartViewModel)
                    .tabItem {
                        Label("カート", systemImage: "cart")
                    }
                    .badge(cartViewModel.itemCount > 0 ? cartViewModel.itemCount : 0)
                    .tag(1)

                // 注文履歴タブ
                OrderHistoryView()
                    .tabItem {
                        Label("注文履歴", systemImage: "list.clipboard")
                    }
                    .tag(2)
            }
            .tint(AsaColors.coffeeBrown)

            // トースト表示
            if let message = cartViewModel.toastMessage {
                VStack {
                    Spacer()

                    ToastView(message: message)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    cartViewModel.clearToast()
                                }
                            }
                        }
                }
                .animation(.easeInOut(duration: 0.3), value: cartViewModel.toastMessage)
            }
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AsaColors.darkSlate.opacity(0.9))
        .clipShape(Capsule())
        .shadow(radius: 4)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Order.self, inMemory: true)
}
