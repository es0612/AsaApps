import SwiftUI

// MARK: - ImagePreviewView
struct ImagePreviewView: View {
    // MARK: - Properties

    @Bindable var viewModel: PhotoEditorViewModel
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景パターン（透明部分の可視化）
                CheckerboardPattern()
                    .opacity(0.3)

                // プレビュー画像
                if let image = viewModel.previewImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .gesture(magnificationGesture)
                        .onTapGesture(count: 2) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                scale = scale > 1.0 ? 1.0 : 2.0
                            }
                        }

                    // 描画モード時のオーバーレイ
                    if viewModel.currentMode == .drawing {
                        DrawingCanvasOverlay(viewModel: viewModel, imageSize: geometry.size)
                    }

                    // テキストモード時のオーバーレイ
                    if viewModel.currentMode == .text {
                        TextLayerOverlay(viewModel: viewModel, imageSize: geometry.size)
                    }
                }

                // Undo/Redoボタン
                VStack {
                    HStack {
                        Spacer()

                        HStack(spacing: 8) {
                            Button {
                                viewModel.undo()
                            } label: {
                                Image(systemName: "arrow.uturn.backward")
                                    .foregroundColor(viewModel.canUndo ? .white : .gray)
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .disabled(!viewModel.canUndo)

                            Button {
                                viewModel.redo()
                            } label: {
                                Image(systemName: "arrow.uturn.forward")
                                    .foregroundColor(viewModel.canRedo ? .white : .gray)
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .disabled(!viewModel.canRedo)
                        }
                        .padding(.trailing, 10)
                    }
                    .padding(.top, 10)

                    Spacer()
                }
            }
        }
        .background(Color.black)
    }

    // MARK: - Gestures

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale = min(max(scale * delta, 1.0), 5.0)
            }
            .onEnded { _ in
                lastScale = 1.0
            }
    }
}

// MARK: - CheckerboardPattern
struct CheckerboardPattern: View {
    let size: CGFloat = 10

    var body: some View {
        Canvas { context, canvasSize in
            let columns = Int(canvasSize.width / size) + 1
            let rows = Int(canvasSize.height / size) + 1

            for row in 0..<rows {
                for col in 0..<columns {
                    if (row + col) % 2 == 0 {
                        let rect = CGRect(
                            x: CGFloat(col) * size,
                            y: CGFloat(row) * size,
                            width: size,
                            height: size
                        )
                        context.fill(Path(rect), with: .color(.gray.opacity(0.3)))
                    }
                }
            }
        }
    }
}

// MARK: - DrawingCanvasOverlay
struct DrawingCanvasOverlay: View {
    @Bindable var viewModel: PhotoEditorViewModel
    let imageSize: CGSize

    var body: some View {
        Canvas { context, size in
            // 既存のストロークを描画
            for layer in viewModel.drawingLayers.reversed() {
                guard layer.isVisible else { continue }

                context.opacity = layer.opacity

                for stroke in layer.strokes {
                    drawStroke(stroke, in: &context, canvasSize: size)
                }
            }

            // 現在描画中のストローク
            if let currentStroke = viewModel.currentStroke {
                drawStroke(currentStroke, in: &context, canvasSize: size)
            }
        }
        .gesture(drawingGesture)
    }

    private func drawStroke(_ stroke: DrawingStroke, in context: inout GraphicsContext, canvasSize: CGSize) {
        guard stroke.points.count > 1 else { return }

        var path = Path()
        let scaledPoints = stroke.points.map { point in
            CGPoint(x: point.x * canvasSize.width, y: point.y * canvasSize.height)
        }

        path.move(to: scaledPoints[0])
        for i in 1..<scaledPoints.count {
            path.addLine(to: scaledPoints[i])
        }

        let strokeStyle = StrokeStyle(
            lineWidth: stroke.lineWidth,
            lineCap: .round,
            lineJoin: .round
        )

        switch stroke.tool {
        case .pen:
            context.stroke(path, with: .color(stroke.color.opacity(stroke.opacity)), style: strokeStyle)
        case .brush:
            context.stroke(path, with: .color(stroke.color.opacity(stroke.opacity * 0.8)), style: strokeStyle)
        case .highlighter:
            context.stroke(path, with: .color(stroke.color.opacity(stroke.opacity * 0.4)), style: strokeStyle)
        case .eraser:
            context.stroke(path, with: .color(.white), style: strokeStyle)
        }
    }

    private var drawingGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let normalizedPoint = CGPoint(
                    x: value.location.x / imageSize.width,
                    y: value.location.y / imageSize.height
                )

                if viewModel.currentStroke == nil {
                    viewModel.startDrawing(at: normalizedPoint)
                } else {
                    viewModel.addDrawingPoint(normalizedPoint)
                }
            }
            .onEnded { _ in
                viewModel.finishDrawing()
            }
    }
}

// MARK: - TextLayerOverlay
struct TextLayerOverlay: View {
    @Bindable var viewModel: PhotoEditorViewModel
    let imageSize: CGSize

    var body: some View {
        ForEach(viewModel.textLayers) { layer in
            TextLayerView(
                layer: layer,
                imageSize: imageSize,
                isSelected: viewModel.selectedTextLayerID == layer.id,
                onSelect: {
                    viewModel.selectedTextLayerID = layer.id
                },
                onPositionChange: { newPosition in
                    var updatedLayer = layer
                    updatedLayer.position = newPosition
                    viewModel.updateTextLayer(updatedLayer)
                }
            )
        }
    }
}

// MARK: - TextLayerView
struct TextLayerView: View {
    let layer: TextLayer
    let imageSize: CGSize
    let isSelected: Bool
    let onSelect: () -> Void
    let onPositionChange: (CGPoint) -> Void

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        let position = CGPoint(
            x: layer.position.x * imageSize.width,
            y: layer.position.y * imageSize.height
        )

        Text(layer.text)
            .font(layer.font)
            .foregroundColor(layer.color)
            .opacity(layer.opacity)
            .rotationEffect(.radians(layer.rotation))
            .position(x: position.x + dragOffset.width, y: position.y + dragOffset.height)
            .overlay(
                isSelected ? selectionBorder : nil
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        let newPosition = CGPoint(
                            x: (position.x + value.translation.width) / imageSize.width,
                            y: (position.y + value.translation.height) / imageSize.height
                        )
                        onPositionChange(newPosition)
                        dragOffset = .zero
                    }
            )
            .onTapGesture {
                onSelect()
            }
    }

    private var selectionBorder: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(Color.asaCoffeeBrown, lineWidth: 2)
            .padding(-8)
    }
}

// MARK: - Preview
#Preview {
    ImagePreviewView(viewModel: PhotoEditorViewModel())
}
