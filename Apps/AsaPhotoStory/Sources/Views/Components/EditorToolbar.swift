import SwiftUI
import AsaUIKit

/// 編集ツールバー
/// 写真追加、テキスト追加、ステッカー、描画、レイアウト変更のボタンを提供する
struct EditorToolbar: View {
    // MARK: - Properties

    let onAddPhoto: () -> Void
    let onAddText: () -> Void
    let onAddSticker: () -> Void
    let onAddDrawing: () -> Void
    let onChangeLayout: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            toolButton(icon: "photo.badge.plus", label: "写真", action: onAddPhoto)
            toolButton(icon: "textformat", label: "テキスト", action: onAddText)
            toolButton(icon: "star.fill", label: "ステッカー", action: onAddSticker)
            toolButton(icon: "pencil.tip", label: "描画", action: onAddDrawing)
            toolButton(icon: "rectangle.3.group", label: "レイアウト", action: onChangeLayout)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Subviews

    private func toolButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(height: 24)
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(AsaColors.darkSlate)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    EditorToolbar(
        onAddPhoto: {},
        onAddText: {},
        onAddSticker: {},
        onAddDrawing: {},
        onChangeLayout: {}
    )
}
