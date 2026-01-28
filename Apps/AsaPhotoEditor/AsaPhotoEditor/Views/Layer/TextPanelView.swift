import SwiftUI

// MARK: - TextPanelView
struct TextPanelView: View {
    // MARK: - Properties

    @Bindable var viewModel: PhotoEditorViewModel
    @State private var showingTextEditor = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // テキストレイヤー一覧
            if viewModel.textLayers.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.textLayers) { layer in
                            TextLayerCard(
                                layer: layer,
                                isSelected: viewModel.selectedTextLayerID == layer.id,
                                onSelect: {
                                    viewModel.selectedTextLayerID = layer.id
                                },
                                onEdit: {
                                    viewModel.selectedTextLayerID = layer.id
                                    showingTextEditor = true
                                },
                                onDelete: {
                                    viewModel.deleteTextLayer(layer.id)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // 追加ボタン
            HStack {
                Spacer()

                Button {
                    viewModel.addTextLayer()
                    showingTextEditor = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("テキストを追加")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.asaCoffeeBrown)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .sheet(isPresented: $showingTextEditor) {
            if let selectedID = viewModel.selectedTextLayerID,
               let index = viewModel.textLayers.firstIndex(where: { $0.id == selectedID }) {
                TextEditorSheet(
                    layer: $viewModel.textLayers[index],
                    onDone: {
                        viewModel.recordHistory()
                        viewModel.schedulePreviewUpdate()
                        showingTextEditor = false
                    }
                )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "textformat")
                .font(.largeTitle)
                .foregroundColor(.asaSoftCream.opacity(0.5))

            Text("テキストを追加して\n画像に文字を入れましょう")
                .font(.caption)
                .foregroundColor(.asaSoftCream.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - TextLayerCard
struct TextLayerCard: View {
    let layer: TextLayer
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.asaMocha.opacity(0.5))
                    .frame(width: 80, height: 60)

                Text(layer.text.prefix(10))
                    .font(.caption)
                    .foregroundColor(layer.color)
                    .lineLimit(2)
                    .frame(width: 70)

                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.asaCoffeeBrown, lineWidth: 2)
                        .frame(width: 80, height: 60)
                }
            }
            .onTapGesture {
                onSelect()
            }

            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.asaSoftCream)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                }
            }
        }
    }
}

// MARK: - TextEditorSheet
struct TextEditorSheet: View {
    @Binding var layer: TextLayer
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedColor: Color

    init(layer: Binding<TextLayer>, onDone: @escaping () -> Void) {
        self._layer = layer
        self.onDone = onDone
        self._selectedColor = State(initialValue: layer.wrappedValue.color)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("テキスト") {
                    TextField("テキストを入力", text: $layer.text)
                }

                Section("フォント") {
                    Picker("フォント", selection: $layer.fontName) {
                        ForEach(FontOption.allCases) { option in
                            Text(option.displayName)
                                .font(option.font)
                                .tag(option.rawValue)
                        }
                    }

                    HStack {
                        Text("サイズ")
                        Slider(value: $layer.fontSize, in: 12...100, step: 1)
                        Text("\(Int(layer.fontSize))")
                            .monospacedDigit()
                            .frame(width: 40)
                    }
                }

                Section("スタイル") {
                    ColorPicker("カラー", selection: $selectedColor)
                        .onChange(of: selectedColor) { _, newColor in
                            layer.updateColor(newColor)
                        }

                    HStack {
                        Text("透明度")
                        Slider(value: $layer.opacity, in: 0.1...1.0)
                        Text("\(Int(layer.opacity * 100))%")
                            .monospacedDigit()
                            .frame(width: 50)
                    }

                    HStack {
                        Text("回転")
                        Slider(value: $layer.rotation, in: -.pi...(.pi))
                        Text("\(Int(layer.rotation * 180 / .pi))°")
                            .monospacedDigit()
                            .frame(width: 50)
                    }
                }
            }
            .navigationTitle("テキスト編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        onDone()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Preview
#Preview {
    TextPanelView(viewModel: PhotoEditorViewModel())
        .background(Color.asaDarkSlate)
}
