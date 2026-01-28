//
//  DrawingToolbar.swift
//  AsaMultiplayerGame
//
//  描画ツールバーコンポーネント
//

import SwiftUI

/// 描画ツールバー
///
/// 色選択、線の太さ選択、消去、Undoなどの描画ツールを提供します。
struct DrawingToolbar: View {
    // MARK: - Properties

    @Binding var selectedColor: StrokeColor
    @Binding var lineWidth: CGFloat

    var onClear: () -> Void
    var onUndo: () -> Void

    let availableLineWidths: [CGFloat] = [2.0, 4.0, 8.0, 12.0]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // 色選択
            colorPicker

            Divider()

            // 線の太さ選択
            lineWidthPicker

            Divider()

            // アクションボタン
            actionButtons
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }

    // MARK: - Color Picker

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("色")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("AsaDarkSlate"))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                ForEach(StrokeColor.allCases, id: \.self) { color in
                    Button {
                        selectedColor = color
                    } label: {
                        ZStack {
                            Circle()
                                .fill(color.color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selectedColor == color ? Color("AsaCoffeeBrown") : Color.gray.opacity(0.3),
                                            lineWidth: selectedColor == color ? 3 : 1
                                        )
                                )

                            if color == .white {
                                Circle()
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    .frame(width: 30, height: 30)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Line Width Picker

    private var lineWidthPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("太さ")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("AsaDarkSlate"))

            HStack(spacing: 12) {
                ForEach(availableLineWidths, id: \.self) { width in
                    Button {
                        lineWidth = width
                    } label: {
                        ZStack {
                            Circle()
                                .fill(lineWidth == width ? Color("AsaSoftCream") : Color.clear)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            lineWidth == width ? Color("AsaCoffeeBrown") : Color.gray.opacity(0.3),
                                            lineWidth: lineWidth == width ? 2 : 1
                                        )
                                )

                            Circle()
                                .fill(Color("AsaDarkSlate"))
                                .frame(width: width, height: width)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Undoボタン
            Button(action: onUndo) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title3)
                    Text("戻す")
                        .font(.caption2)
                }
                .foregroundColor(Color("AsaDarkSlate"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color("AsaSoftCream"))
                .cornerRadius(8)
            }

            // クリアボタン
            Button(action: onClear) {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.title3)
                    Text("消去")
                        .font(.caption2)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var color: StrokeColor = .black
        @State private var width: CGFloat = 4.0

        var body: some View {
            DrawingToolbar(
                selectedColor: $color,
                lineWidth: $width,
                onClear: { print("Clear") },
                onUndo: { print("Undo") }
            )
            .padding()
        }
    }

    return PreviewWrapper()
}
