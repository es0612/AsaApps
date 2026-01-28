import SwiftUI

// MARK: - DrawingPanelView
struct DrawingPanelView: View {
    // MARK: - Properties

    @Bindable var viewModel: PhotoEditorViewModel
    @State private var showingLayerManager = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // ツール選択
            HStack(spacing: 16) {
                ForEach(DrawingTool.allCases) { tool in
                    DrawingToolButton(
                        tool: tool,
                        isSelected: viewModel.currentDrawingTool == tool
                    ) {
                        viewModel.currentDrawingTool = tool
                        viewModel.drawingLineWidth = tool.defaultLineWidth
                    }
                }

                Spacer()

                // レイヤー管理ボタン
                Button {
                    showingLayerManager = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "square.3.layers.3d")
                            .font(.title3)
                        Text("レイヤー")
                            .font(.caption2)
                    }
                    .foregroundColor(.asaSoftCream)
                }

                // アンドゥボタン
                Button {
                    viewModel.undoDrawing()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.title3)
                        Text("戻す")
                            .font(.caption2)
                    }
                    .foregroundColor(.asaSoftCream)
                }
            }
            .padding(.horizontal)

            // カラーと線幅
            HStack(spacing: 16) {
                // カラーピッカー
                ColorPicker("", selection: $viewModel.drawingColor)
                    .labelsHidden()
                    .frame(width: 30, height: 30)

                // プリセットカラー
                HStack(spacing: 8) {
                    ForEach(presetColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(viewModel.drawingColor == color ? Color.white : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                viewModel.drawingColor = color
                            }
                    }
                }

                Spacer()

                // 線幅スライダー
                HStack(spacing: 8) {
                    Image(systemName: "minus")
                        .font(.caption)
                        .foregroundColor(.asaSoftCream.opacity(0.5))

                    Slider(
                        value: $viewModel.drawingLineWidth,
                        in: viewModel.currentDrawingTool.lineWidthRange
                    )
                    .tint(Color.asaCoffeeBrown)
                    .frame(width: 100)

                    Image(systemName: "plus")
                        .font(.caption)
                        .foregroundColor(.asaSoftCream.opacity(0.5))
                }
            }
            .padding(.horizontal)

            // クリアボタン
            HStack {
                Spacer()

                Button {
                    viewModel.clearDrawingLayer()
                } label: {
                    Text("レイヤーをクリア")
                        .font(.caption)
                        .foregroundColor(.asaSoftCream.opacity(0.7))
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .sheet(isPresented: $showingLayerManager) {
            DrawingLayerManagerSheet(viewModel: viewModel)
        }
    }

    // MARK: - Preset Colors

    private var presetColors: [Color] {
        [
            .black, .white, .red, .orange, .yellow, .green, .blue, .purple
        ]
    }
}

// MARK: - DrawingToolButton
struct DrawingToolButton: View {
    let tool: DrawingTool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tool.iconName)
                    .font(.title3)
                Text(tool.rawValue)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .white : .asaSoftCream.opacity(0.7))
            .frame(width: 50, height: 45)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.asaCoffeeBrown : Color.clear)
            )
        }
    }
}

// MARK: - DrawingLayerManagerSheet
struct DrawingLayerManagerSheet: View {
    @Bindable var viewModel: PhotoEditorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.drawingLayers) { layer in
                    DrawingLayerRow(
                        layer: layer,
                        isSelected: viewModel.selectedDrawingLayerID == layer.id,
                        onSelect: {
                            viewModel.selectedDrawingLayerID = layer.id
                        },
                        onToggleVisibility: {
                            if let index = viewModel.drawingLayers.firstIndex(where: { $0.id == layer.id }) {
                                viewModel.drawingLayers[index].isVisible.toggle()
                                viewModel.schedulePreviewUpdate()
                            }
                        },
                        onToggleLock: {
                            if let index = viewModel.drawingLayers.firstIndex(where: { $0.id == layer.id }) {
                                viewModel.drawingLayers[index].isLocked.toggle()
                            }
                        },
                        onDelete: {
                            viewModel.deleteDrawingLayer(layer.id)
                        }
                    )
                }
                .onMove { from, to in
                    viewModel.drawingLayers.move(fromOffsets: from, toOffset: to)
                    viewModel.schedulePreviewUpdate()
                }
            }
            .listStyle(.plain)
            .navigationTitle("レイヤー管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.addDrawingLayer()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(viewModel.drawingLayers.count >= 10)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - DrawingLayerRow
struct DrawingLayerRow: View {
    let layer: DrawingLayer
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleVisibility: () -> Void
    let onToggleLock: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            // 選択インジケーター
            Circle()
                .fill(isSelected ? Color.asaCoffeeBrown : Color.clear)
                .frame(width: 8, height: 8)

            Text(layer.name)
                .foregroundColor(layer.isVisible ? .primary : .secondary)

            if layer.isEmpty {
                Text("(空)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 表示/非表示
            Button(action: onToggleVisibility) {
                Image(systemName: layer.isVisible ? "eye" : "eye.slash")
                    .foregroundColor(layer.isVisible ? .asaCoffeeBrown : .gray)
            }
            .buttonStyle(.plain)

            // ロック
            Button(action: onToggleLock) {
                Image(systemName: layer.isLocked ? "lock.fill" : "lock.open")
                    .foregroundColor(layer.isLocked ? .asaCoffeeBrown : .gray)
            }
            .buttonStyle(.plain)

            // 削除
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Preview
#Preview {
    DrawingPanelView(viewModel: PhotoEditorViewModel())
        .background(Color.asaDarkSlate)
}
