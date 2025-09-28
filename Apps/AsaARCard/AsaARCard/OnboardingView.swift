import SwiftUI
import AsaUIKit

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    let onComplete: () -> Void

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "arkit",
            title: "AR名刺へようこそ",
            description: "拡張現実（AR）を使って、あなたの名刺を3D空間に表示できます。まずは使い方を見てみましょう。",
            systemImage: "hand.wave.fill",
            color: AsaColors.coffeeBrown
        ),
        OnboardingPage(
            icon: "camera.viewfinder",
            title: "カメラを向けて平面検出",
            description: "床や机などの水平な面にカメラを向けてください。ARが平面を検出すると、名刺を配置できるようになります。",
            systemImage: "camera.fill",
            color: AsaColors.mocha
        ),
        OnboardingPage(
            icon: "eye.fill",
            title: "目のアイコンで表示",
            description: "画面下部の「目」アイコンをタップすると、AR名刺が表示されます。もう一度タップすると非表示になります。",
            systemImage: "eye.fill",
            color: AsaColors.mutedSage
        ),
        OnboardingPage(
            icon: "arrow.triangle.2.circlepath",
            title: "名刺を回転して裏面表示",
            description: "回転アイコンをタップすると、名刺が180度回転して裏面が見えます。設定ボタンで名刺情報を編集できます。",
            systemImage: "arrow.triangle.2.circlepath",
            color: AsaColors.darkSlate
        )
    ]

    var body: some View {
        ZStack {
            AsaColors.softCream.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button("スキップ") {
                        completeOnboarding()
                    }
                    .foregroundColor(AsaColors.mutedSage)
                    .padding()
                }

                Spacer()

                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(height: 500)

                Spacer()

                if currentPage == pages.count - 1 {
                    AsaButton(
                        title: "始める",
                        action: completeOnboarding,
                        color: AsaColors.coffeeBrown
                    )
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                } else {
                    Button("次へ") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .font(.headline)
                    .foregroundColor(AsaColors.coffeeBrown)
                    .padding()
                }
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "AsaARCard_HasCompletedOnboarding")
        onComplete()
        dismiss()
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let systemImage: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: page.systemImage)
                .font(.system(size: 80))
                .foregroundColor(page.color)
                .frame(width: 150, height: 150)
                .background(
                    Circle()
                        .fill(page.color.opacity(0.2))
                )
                .shadow(color: page.color.opacity(0.3), radius: 10)

            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AsaColors.darkSlate)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text(page.description)
                .font(.body)
                .foregroundColor(AsaColors.darkSlate.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(6)
        }
        .padding()
    }
}

#Preview {
    OnboardingView(onComplete: {})
}