import SwiftUI
import AsaPhotoStoryKit

/// ステッカー要素ビュー
/// SF SymbolsをステッカーとしてSF Symbolを表示する
struct StickerElementView: View {
    let element: StoryElement

    var body: some View {
        Image(systemName: element.stickerName ?? "star.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(resolveColor())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(4)
    }

    private func resolveColor() -> Color {
        if let hex = element.textColorHex {
            return Color(hex: hex)
        }
        return .orange
    }
}

#Preview {
    StickerElementView(element: StoryElement(type: .sticker))
        .frame(width: 80, height: 80)
}
