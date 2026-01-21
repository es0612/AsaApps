import SwiftUI
import AsaUIKit

// MARK: - OnboardingView
/// チュートリアル画面
struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "target",
            title: "的当てゲーム",
            description: "AR空間に出現するターゲットをタップして得点を稼ごう！",
            color: .red
        ),
        OnboardingPage(
            icon: "viewfinder",
            title: "平面を検出",
            description: "まずカメラを床やテーブルなどの平面に向けてください。平面が検出されるとゲームを開始できます。",
            color: .blue
        ),
        OnboardingPage(
            icon: "hand.tap.fill",
            title: "タップでヒット",
            description: "ターゲットは3秒で消えてしまいます。素早くタップしてヒットしよう！",
            color: .orange
        ),
        OnboardingPage(
            icon: "flame.fill",
            title: "コンボボーナス",
            description: "連続でヒットするとコンボボーナス！最大+25点のボーナスがもらえます。",
            color: .purple
        )
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景
            AsaColors.softCream.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ページコンテンツ
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // ページインジケーター
                pageIndicator
                    .padding(.bottom, 24)

                // ボタン
                buttonSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Subviews

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()

            // アイコン
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 150, height: 150)

                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundColor(page.color)
            }

            // テキスト
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AsaColors.darkSlate)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(AsaColors.mutedSage)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? AsaColors.coffeeBrown : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentPage ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
    }

    private var buttonSection: some View {
        HStack(spacing: 16) {
            if currentPage > 0 {
                Button(action: previousPage) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("戻る")
                    }
                    .font(.headline)
                    .foregroundColor(AsaColors.coffeeBrown)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AsaColors.coffeeBrown, lineWidth: 2)
                    )
                }
            }

            Button(action: nextOrComplete) {
                HStack {
                    Text(isLastPage ? "始める" : "次へ")
                    Image(systemName: isLastPage ? "play.fill" : "chevron.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AsaColors.coffeeBrown, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Actions

    private var isLastPage: Bool {
        currentPage == pages.count - 1
    }

    private func nextOrComplete() {
        if isLastPage {
            onComplete()
        } else {
            withAnimation {
                currentPage += 1
            }
        }
    }

    private func previousPage() {
        withAnimation {
            currentPage = max(0, currentPage - 1)
        }
    }
}

// MARK: - OnboardingPage Model

private struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}
