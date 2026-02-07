import SwiftUI
import AsaUIKit

/// 空状態ビュー
/// ストーリーがない場合に表示される、イラスト付きの案内画面
struct EmptyStateView: View {
    let onCreateStory: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // イラスト
            ZStack {
                Circle()
                    .fill(AsaColors.softCream.opacity(0.5))
                    .frame(width: 140, height: 140)

                Image(systemName: "book.pages")
                    .font(.system(size: 56))
                    .foregroundColor(AsaColors.coffeeBrown)
            }

            // 説明テキスト
            VStack(spacing: 8) {
                Text("まだストーリーがありません")
                    .font(.title2.bold())
                    .foregroundColor(AsaColors.darkSlate)

                Text("家族の思い出を写真で綴る\nフォトストーリーを作ってみましょう")
                    .font(.subheadline)
                    .foregroundColor(AsaColors.mutedSage)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // 作成ボタン
            AsaButton(
                title: "最初のストーリーを作る",
                action: onCreateStory,
                color: AsaColors.coffeeBrown
            )
            .frame(width: 240)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    EmptyStateView(onCreateStory: {})
}
