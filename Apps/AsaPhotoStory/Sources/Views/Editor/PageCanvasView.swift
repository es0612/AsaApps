import SwiftUI
import AsaUIKit
import AsaPhotoStoryKit

/// ページキャンバスビュー
/// 16:9アスペクト比のキャンバス上で要素を配置・編集する
struct PageCanvasView: View {
    // MARK: - Properties

    let page: StoryPage
    @Binding var selectedElementId: UUID?
    @State private var dragOffset: [UUID: CGSize] = [:]

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let canvasSize = calculateCanvasSize(in: geometry.size)

            ZStack {
                // 背景
                canvasBackground(size: canvasSize)

                // 要素表示
                ForEach(page.sortedElements) { element in
                    elementView(for: element, canvasSize: canvasSize)
                        .position(
                            x: element.positionX * canvasSize.width + (dragOffset[element.id]?.width ?? 0),
                            y: element.positionY * canvasSize.height + (dragOffset[element.id]?.height ?? 0)
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedElementId = element.id
                            }
                        }
                        .gesture(dragGesture(for: element, canvasSize: canvasSize))
                        .overlay(
                            selectionOverlay(for: element)
                        )
                }
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture {
                selectedElementId = nil
            }
        }
    }

    // MARK: - Canvas Helpers

    /// 16:9アスペクト比でキャンバスサイズを計算
    private func calculateCanvasSize(in availableSize: CGSize) -> CGSize {
        let aspectRatio: CGFloat = 16.0 / 9.0
        let width = availableSize.width
        let height = width / aspectRatio

        if height <= availableSize.height {
            return CGSize(width: width, height: height)
        } else {
            let adjustedWidth = availableSize.height * aspectRatio
            return CGSize(width: adjustedWidth, height: availableSize.height)
        }
    }

    private func canvasBackground(size: CGSize) -> some View {
        Group {
            if let bgColorHex = page.backgroundColorHex {
                Color(hex: bgColorHex)
            } else {
                Color.white
            }
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: - Element Views

    @ViewBuilder
    private func elementView(for element: StoryElement, canvasSize: CGSize) -> some View {
        let width = element.width * canvasSize.width
        let height = element.height * canvasSize.height

        Group {
            switch element.elementType {
            case .photo:
                PhotoElementView(element: element)
            case .text:
                TextElementView(element: element)
            case .sticker:
                StickerElementView(element: element)
            case .drawing:
                DrawingElementView(element: element)
            }
        }
        .frame(width: width, height: height)
        .rotationEffect(.degrees(element.rotation))
        .opacity(element.opacity)
    }

    // MARK: - Selection Overlay

    @ViewBuilder
    private func selectionOverlay(for element: StoryElement) -> some View {
        if selectedElementId == element.id {
            RoundedRectangle(cornerRadius: 4)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 3]))
                .foregroundColor(.blue)
                .padding(-4)
        }
    }

    // MARK: - Gestures

    private func dragGesture(for element: StoryElement, canvasSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset[element.id] = value.translation
            }
            .onEnded { value in
                let deltaX = value.translation.width / canvasSize.width
                let deltaY = value.translation.height / canvasSize.height
                element.positionX = max(0, min(1, element.positionX + deltaX))
                element.positionY = max(0, min(1, element.positionY + deltaY))
                dragOffset[element.id] = nil
            }
    }
}


#Preview {
    PageCanvasView(
        page: StoryPage(order: 0),
        selectedElementId: .constant(nil)
    )
    .padding()
}
