import SwiftUI
import AsaUIKit

/// テキスト編集シート
/// テキスト入力、フォント選択、色選択、サイズ調整を提供する
struct TextEditorSheetView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var selectedFontName = "System"
    @State private var fontSize: Double = 20.0
    @State private var selectedColor = Color.black

    let onApply: (_ text: String, _ fontName: String, _ fontSize: Double, _ colorHex: String) -> Void

    private let fontOptions = [
        "System",
        "Helvetica Neue",
        "Georgia",
        "Courier New",
        "Avenir Next",
        "Futura",
        "Didot",
        "Gill Sans",
        "Hiragino Sans",
        "Hiragino Mincho ProN",
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // テキスト入力セクション
                Section("テキスト") {
                    TextEditor(text: $text)
                        .frame(minHeight: 100)
                        .font(previewFont)
                        .foregroundColor(selectedColor)
                }

                // フォント選択セクション
                Section("フォント") {
                    Picker("フォント", selection: $selectedFontName) {
                        ForEach(fontOptions, id: \.self) { fontName in
                            Text(fontName)
                                .font(fontName == "System" ? .body : .custom(fontName, size: 16))
                                .tag(fontName)
                        }
                    }
                }

                // サイズ調整セクション
                Section("サイズ: \(Int(fontSize))pt") {
                    Slider(value: $fontSize, in: 10...72, step: 1)
                        .tint(AsaColors.coffeeBrown)
                }

                // 色選択セクション
                Section("テキストカラー") {
                    ColorPicker("文字色を選択", selection: $selectedColor)

                    // プリセットカラー
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(presetColors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // プレビューセクション
                Section("プレビュー") {
                    Text(text.isEmpty ? "テキストを入力してください" : text)
                        .font(previewFont)
                        .foregroundColor(text.isEmpty ? .gray : selectedColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .navigationTitle("テキスト編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("適用") {
                        let colorHex = selectedColor.toHex()
                        onApply(text, selectedFontName, fontSize, colorHex)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(AsaColors.coffeeBrown)
                    .disabled(text.isEmpty)
                }
            }
        }
    }

    // MARK: - Computed

    private var previewFont: Font {
        let size = fontSize
        if selectedFontName == "System" {
            return .system(size: size)
        }
        return .custom(selectedFontName, size: size)
    }

    private var presetColors: [Color] {
        [
            .black, .white, .red, .orange, .yellow,
            .green, .blue, .purple, .pink, .brown,
            AsaColors.coffeeBrown, AsaColors.mocha, AsaColors.darkSlate,
        ]
    }
}

// MARK: - Color to Hex Extension

private extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}

#Preview {
    TextEditorSheetView { _, _, _, _ in }
}
