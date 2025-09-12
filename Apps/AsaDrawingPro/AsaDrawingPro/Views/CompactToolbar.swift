//
//  CompactToolbar.swift
//  AsaDrawingPro
//  
//  Created on 2025/09/12
//

import SwiftUI

struct CompactToolbar: View {
    @Bindable var viewModel: DrawingProViewModel
    @State private var showColorPicker = false
    @State private var showBrushSettings = false
    
    var body: some View {
        VStack(spacing: 12) {
            // 主要ツール選択
            toolSelection
            
            // カラーとサイズ設定
            colorAndSizeControls
            
            // アクションボタン
            actionButtons
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.asaDarkSlate.opacity(0.1), radius: 10, x: 0, y: -2)
        )
        .sheet(isPresented: $showColorPicker) {
            ColorPickerSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showBrushSettings) {
            BrushSettingsSheet(viewModel: viewModel)
        }
    }
    
    // MARK: - Tool Selection
    
    private var toolSelection: some View {
        HStack(spacing: 16) {
            ForEach(DrawingTool.allCases, id: \.self) { tool in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedTool = tool
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tool.iconName)
                            .font(.title2)
                            .frame(width: 24, height: 24)
                        
                        Text(tool.rawValue)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    .foregroundColor(
                        viewModel.selectedTool == tool ? .white : Color.asaDarkSlate
                    )
                    .frame(width: 70, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                viewModel.selectedTool == tool ? 
                                ColorColor.asaCoffeeBrown : .clear
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Color and Size Controls
    
    private var colorAndSizeControls: some View {
        HStack(spacing: 16) {
            // カラー選択
            Button(action: {
                showColorPicker = true
            }) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.selectedColor)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Color.asaMutedSage.opacity(0.3), lineWidth: 1)
                        )
                    
                    Text("色")
                        .font(.caption)
                        .foregroundColor(Color.asaDarkSlate)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.asaSoftCream.opacity(0.3))
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // ブラシサイズ
            Button(action: {
                showBrushSettings = true
            }) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.asaDarkSlate)
                        .frame(width: CGFloat(viewModel.brushSize))
                        .frame(width: 24, height: 24)
                    
                    Text("サイズ: \(Int(viewModel.brushSize))")
                        .font(.caption)
                        .foregroundColor(Color.asaDarkSlate)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.asaSoftCream.opacity(0.3))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // アンドゥ
            Button(action: {
                viewModel.undo()
            }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.title3)
                    .foregroundColor(Color.asaMutedSage)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.8))
                    )
            }
            .disabled(viewModel.selectedLayer?.strokes.isEmpty ?? true)
            
            Spacer()
            
            // クリア
            Button(action: {
                viewModel.clearCurrentLayer()
            }) {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundColor(Color.asaMocha)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.8))
                    )
            }
            .disabled(viewModel.selectedLayer?.strokes.isEmpty ?? true)
        }
    }
}

// MARK: - Color Picker Sheet

struct ColorPickerSheet: View {
    @Bindable var viewModel: DrawingProViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // プリセットカラー
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                    ForEach(Color.presetColors, id: \.self) { color in
                        Button(action: {
                            viewModel.selectedColor = color
                            dismiss()
                        }) {
                            Circle()
                                .fill(color)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: 3)
                                        .opacity(viewModel.selectedColor == color ? 1 : 0)
                                )
                                .shadow(radius: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                
                Divider()
                
                // カスタムカラーピッカー
                ColorPicker("カスタムカラー", selection: $viewModel.selectedColor)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("色を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Brush Settings Sheet

struct BrushSettingsSheet: View {
    @Bindable var viewModel: DrawingProViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // ブラシサイズプレビュー
                VStack(spacing: 16) {
                    Text("ブラシサイズ: \(Int(viewModel.brushSize))pt")
                        .font(.headline)
                        .foregroundColor(Color.asaDarkSlate)
                    
                    Circle()
                        .fill(viewModel.selectedColor)
                        .frame(width: CGFloat(viewModel.brushSize * 2), height: CGFloat(viewModel.brushSize * 2))
                        .shadow(radius: 2)
                }
                .frame(height: 100)
                
                // サイズスライダー
                VStack(spacing: 16) {
                    HStack {
                        Text("1")
                            .font(.caption)
                            .foregroundColor(Color.asaMutedSage)
                        
                        Slider(value: $viewModel.brushSize, in: 1...20, step: 1)
                            .tint(Color.asaCoffeeBrown)
                        
                        Text("20")
                            .font(.caption)
                            .foregroundColor(Color.asaMutedSage)
                    }
                    
                    // プリセットサイズ
                    HStack(spacing: 12) {
                        ForEach([1, 3, 5, 10, 15, 20], id: \.self) { size in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.brushSize = CGFloat(size)
                                }
                            }) {
                                Text("\(size)")
                                    .font(.caption)
                                    .foregroundColor(
                                        viewModel.brushSize == CGFloat(size) ? .white : Color.asaDarkSlate
                                    )
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(
                                                viewModel.brushSize == CGFloat(size) ? 
                                                ColorColor.asaCoffeeBrown : Color.asaSoftCream.opacity(0.5)
                                            )
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("ブラシ設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}