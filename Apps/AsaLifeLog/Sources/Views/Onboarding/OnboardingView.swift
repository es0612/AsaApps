import SwiftUI

// MARK: - OnboardingView

/// オンボーディングビュー
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, description: String)] = [
        ("book.pages", "AsaLifeLogへようこそ", "あなたの毎日を美しく記録し、振り返りましょう"),
        ("clock", "タイムラインで管理", "健康データ、場所、写真、気分をひとつのタイムラインに"),
        ("chart.bar", "チャートで可視化", "6種類のチャートであなたの生活パターンを可視化"),
        ("lightbulb", "AIインサイト", "ヒューリスティック分析で朝活スコアや相関パターンを発見"),
    ]

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 24) {
                        Image(systemName: page.icon)
                            .font(.system(size: 80))
                            .foregroundStyle(Color.accentColor)

                        Text(page.title)
                            .font(.title2.weight(.bold))

                        Text(page.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    dismiss()
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "次へ" : "はじめる")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}
