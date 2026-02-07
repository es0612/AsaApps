import SwiftUI
import PencilKit
import AsaPhotoStoryKit

/// 描画要素ビュー
/// PencilKitで作成された描画データを表示する
struct DrawingElementView: View {
    let element: StoryElement

    var body: some View {
        Group {
            if let drawingData = element.drawingData,
               let drawing = try? PKDrawing(data: drawingData) {
                DrawingCanvasRepresentable(drawing: drawing)
            } else {
                // 描画プレースホルダー
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .overlay {
                        Image(systemName: "scribble")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.5))
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - PencilKit Canvas Representable

private struct DrawingCanvasRepresentable: UIViewRepresentable {
    let drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawing = drawing
        canvasView.isUserInteractionEnabled = false
        canvasView.backgroundColor = .clear
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
    }
}

#Preview {
    DrawingElementView(element: StoryElement(type: .drawing))
        .frame(width: 200, height: 200)
}
