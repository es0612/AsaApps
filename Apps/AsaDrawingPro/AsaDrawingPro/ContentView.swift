//
//  ContentView.swift
//  AsaDrawingPro
//  
//  Created on 2025/09/12
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = DrawingProViewModel()
    @State private var showLayerManager = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color.asaSoftCream.opacity(0.2)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // コンパクトヘッダー
                    compactHeader
                    
                    // メインキャンバスエリア
                    canvasArea
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // 下部ツールバー
                    CompactToolbar(viewModel: viewModel)
                        .padding(.horizontal, 8)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
                }
            }
        }
        .sheet(isPresented: $showLayerManager) {
            LayerManagerSheet(viewModel: viewModel)
        }
        .gesture(
            // スワイプジェスチャーでアンドゥ/リドゥ
            DragGesture()
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height
                    
                    // 水平方向のスワイプのみ処理
                    if abs(horizontalAmount) > abs(verticalAmount) && abs(horizontalAmount) > 50 {
                        if horizontalAmount < 0 {
                            // 左スワイプでアンドゥ
                            viewModel.undo()
                        }
                        // 右スワイプは将来的にリドゥ実装時に使用
                    }
                }
        )
    }
    
    // MARK: - Compact Header
    
    private var compactHeader: some View {
        HStack {
            // アプリタイトル
            Text("AsaDrawingPro")
                .font(.headline)
                .foregroundColor(.asaCoffeeBrown)
            
            Spacer()
            
            // 現在のレイヤー表示
            Button(action: {
                showLayerManager = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.stack.3d.up")
                        .font(.callout)
                    
                    Text(viewModel.selectedLayer?.name ?? "レイヤー")
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundColor(.asaDarkSlate)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.8))
                        .stroke(Color.asaMutedSage.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 0)
        )
    }
    
    // MARK: - Canvas Area
    
    private var canvasArea: some View {
        ZStack {
            // メインキャンバス
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .stroke(Color.asaMutedSage.opacity(0.2), lineWidth: 1)
                .shadow(color: .asaDarkSlate.opacity(0.08), radius: 12, x: 0, y: 4)
                .overlay(
                    CanvasLayerView(viewModel: viewModel)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            // キャンバスの状態表示
            VStack {
                Spacer()
                
                HStack {
                    // 左上：現在のツール表示
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.selectedTool.iconName)
                            .font(.caption2)
                        Text(viewModel.selectedTool.rawValue)
                            .font(.caption2)
                    }
                    .foregroundColor(.asaMutedSage)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.white.opacity(0.9))
                    )
                    
                    Spacer()
                    
                    // 右上：ストローク数表示
                    Text("\(viewModel.selectedLayer?.strokes.count ?? 0) ストローク")
                        .font(.caption2)
                        .foregroundColor(.asaMutedSage)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white.opacity(0.9))
                        )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Canvas Layer View (Updated)

struct EnhancedCanvasLayerView: View {
    @Bindable var viewModel: DrawingProViewModel
    
    var body: some View {
        Canvas { context, size in
            // 各レイヤーを下から順に描画
            for layer in viewModel.layers.reversed() {
                guard layer.isVisible else { continue }
                
                context.opacity = layer.opacity
                
                for stroke in layer.strokes {
                    drawStroke(stroke, in: context)
                }
            }
            
            // 現在描画中のストローク
            if let currentStroke = viewModel.currentStroke {
                drawStroke(currentStroke, in: context)
            }
        }
        .frame(minWidth: 200, minHeight: 300)
        .background(Color.white)
        .gesture(drawingGesture)
    }
    
    // MARK: - Drawing Methods
    
    private func drawStroke(_ stroke: DrawingStroke, in context: GraphicsContext) {
        guard stroke.points.count > 1 else { return }
        
        var path = Path()
        path.move(to: stroke.points[0])
        
        for i in 1..<stroke.points.count {
            path.addLine(to: stroke.points[i])
        }
        
        let strokeStyle = StrokeStyle(
            lineWidth: stroke.lineWidth,
            lineCap: .round,
            lineJoin: .round
        )
        
        switch stroke.tool {
        case .pen:
            context.stroke(
                path,
                with: .color(stroke.color),
                style: strokeStyle
            )
        case .eraser:
            context.stroke(
                path,
                with: .color(.white),
                style: strokeStyle
            )
        case .highlighter:
            context.stroke(
                path,
                with: .color(stroke.color.opacity(stroke.opacity)),
                style: strokeStyle
            )
        }
    }
    
    // MARK: - Gesture
    
    private var drawingGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if viewModel.currentStroke == nil {
                    viewModel.startDrawing(at: value.location)
                } else {
                    viewModel.addPoint(value.location)
                }
            }
            .onEnded { _ in
                viewModel.finishDrawing()
            }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}