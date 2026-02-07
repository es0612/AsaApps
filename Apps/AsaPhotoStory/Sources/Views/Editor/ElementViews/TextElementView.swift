import SwiftUI
import AsaPhotoStoryKit

/// テキスト要素ビュー
/// フォント、色、サイズを反映したテキストを表示する
struct TextElementView: View {
    let element: StoryElement

    var body: some View {
        Text(element.text ?? "テキスト")
            .font(resolveFont())
            .foregroundColor(resolveColor())
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(8)
    }

    // MARK: - Helpers

    private func resolveFont() -> Font {
        let size = element.fontSize ?? 16.0
        if let fontName = element.fontName, !fontName.isEmpty {
            return .custom(fontName, size: size)
        }
        return .system(size: size, weight: .regular)
    }

    private func resolveColor() -> Color {
        if let hex = element.textColorHex {
            return Color(hex: hex)
        }
        return .primary
    }
}

#Preview {
    TextElementView(element: StoryElement(type: .text))
        .frame(width: 200, height: 100)
        .border(Color.gray)
}
