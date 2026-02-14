import SwiftUI
import TipKit
import AsaUIKit
import AsaCommunityKit

/// オンボーディング画面
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    var onComplete: () -> Void

    private let pages: [(iconName: String, title: String, description: String)] = [
        ("house.fill", "地域とつながる", "ご近所の最新情報や\nイベント情報をチェックしましょう"),
        ("bubble.left.and.bubble.right.fill", "掲示板で交流", "質問、お譲り、子育て情報など\n地域の声を共有できます"),
        ("calendar", "イベントに参加", "町内会行事や地域の集まりに\nワンタップで参加表明"),
        ("shield.checkered", "防災情報", "避難所マップやゴミ出しカレンダーで\n安心・安全な暮らしをサポート"),
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // MARK: - Page Content
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(spacing: 20) {
                        Image(systemName: pages[index].iconName)
                            .font(.system(size: 60))
                            .foregroundStyle(AsaColors.coffeeBrown)
                        Text(pages[index].title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(AsaColors.darkSlate)
                        Text(pages[index].description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 280)

            Spacer()

            // MARK: - Action Button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    onComplete()
                    dismiss()
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "次へ" : "はじめる")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AsaColors.coffeeBrown)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if currentPage < pages.count - 1 {
                Button("スキップ") {
                    onComplete()
                    dismiss()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding(32)
    }
}

// MARK: - Feature Tips

/// 掲示板機能のTip
struct PostFeedTip: Tip {
    var title: Text {
        Text("掲示板を活用しよう")
    }
    var message: Text? {
        Text("カテゴリ別に投稿を閲覧・作成できます。回覧板もデジタルで確認！")
    }
    var image: Image? {
        Image(systemName: "bubble.left.and.bubble.right")
    }
}

/// マップ機能のTip
struct MapFeatureTip: Tip {
    var title: Text {
        Text("マップで地域を探索")
    }
    var message: Text? {
        Text("投稿、イベント、お店、避難所をマップ上で確認できます")
    }
    var image: Image? {
        Image(systemName: "map")
    }
}
