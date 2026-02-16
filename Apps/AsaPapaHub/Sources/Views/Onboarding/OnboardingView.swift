import SwiftUI
import AsaUIKit

// MARK: - オンボーディングビュー

/// 初回起動時のオンボーディング
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    // MARK: - ページデータ

    private let pages: [(String, String, String)] = [
        (
            "sunrise.fill",
            "AsaPapaHub へようこそ",
            "朝活パパのためのライフハブアプリ。\n6つのドメインで生活全体を管理しましょう。"
        ),
        (
            "square.grid.2x2.fill",
            "6つのライフドメイン",
            "朝活・健康・家族・資産・地域・学習。\nあなたの生活を多角的にサポートします。"
        ),
        (
            "sparkles",
            "AIでスマートに",
            "AIブリーフィングやスマート提案で\n毎朝をもっと充実させましょう。"
        ),
    ]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // ページコンテンツ
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    pageView(index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            // ボタンエリア
            VStack(spacing: 12) {
                if currentPage < pages.count - 1 {
                    Button {
                        withAnimation { currentPage += 1 }
                    } label: {
                        Text("次へ")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AsaColors.coffeeBrown, in: RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    NavigationLink {
                        DomainSelectionView(isPresented: $isPresented)
                    } label: {
                        Text("始める")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AsaColors.coffeeBrown, in: RoundedRectangle(cornerRadius: 12))
                    }
                }

                Button("スキップ") {
                    completeOnboarding()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    // MARK: - ページビュー

    private func pageView(index: Int) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: pages[index].0)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AsaColors.coffeeBrown, AsaColors.mocha],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(pages[index].1)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(pages[index].2)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Private

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        isPresented = false
    }
}
