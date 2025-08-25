import SwiftUI

// MARK: - MindMapCanvasView

struct MindMapCanvasView: View {
    @Bindable var viewModel: MindMapViewModel
    @State private var lastScaleValue: CGFloat = 1.0
    @State private var lastOffsetValue = CGSize.zero
    @State private var showAddNodeSheet = false
    @State private var tapLocation = CGPoint.zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                canvasBackground
                    .onTapGesture(count: 2) { location in
                        handleDoubleTap(at: location, in: geometry)
                    }
                    .onTapGesture { _ in
                        dismissSelection()
                    }
                
                // 接続線レイヤー
                ConnectionsLayer(viewModel: viewModel)
                    .allowsHitTesting(!viewModel.isPanGestureActive)
                
                // ノードレイヤー
                nodesLayer
                    .allowsHitTesting(!viewModel.isPanGestureActive)
                
                // マインドマップが空の場合のプレースホルダー
                if viewModel.currentNodes.isEmpty {
                    emptyStateView
                }
            }
            .scaleEffect(viewModel.canvasScale)
            .offset(viewModel.canvasOffset)
            .gesture(simultaneousGestures)
            .clipped()
        }
        .background(Color("AsaSoftCream").opacity(0.3))
        .sheet(isPresented: $showAddNodeSheet) {
            AddNodeSheet(
                viewModel: viewModel,
                position: tapLocation,
                isPresented: $showAddNodeSheet
            )
        }
    }
    
    // MARK: - Canvas Background
    
    private var canvasBackground: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color("AsaSoftCream").opacity(0.1),
                        Color("AsaDarkSlate").opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                gridPattern
                    .opacity(0.2)
            )
    }
    
    // MARK: - Grid Pattern
    
    private var gridPattern: some View {
        Canvas { context, size in
            let spacing: CGFloat = 50 * viewModel.canvasScale
            let offsetX = viewModel.canvasOffset.width.truncatingRemainder(dividingBy: spacing)
            let offsetY = viewModel.canvasOffset.height.truncatingRemainder(dividingBy: spacing)
            
            // 垂直線
            var x = offsetX
            while x < size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(Color("AsaMutedSage").opacity(0.3)), lineWidth: 1)
                x += spacing
            }
            
            // 水平線
            var y = offsetY
            while y < size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(Color("AsaMutedSage").opacity(0.3)), lineWidth: 1)
                y += spacing
            }
        }
    }
    
    // MARK: - Nodes Layer
    
    private var nodesLayer: some View {
        ZStack {
            ForEach(viewModel.currentNodes) { node in
                NodeView(viewModel: viewModel, node: node)
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(Color("AsaMutedSage"))
            
            VStack(spacing: 8) {
                Text("マインドマップを作成しましょう")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text("画面をダブルタップしてノードを追加")
                    .font(.body)
                    .foregroundColor(Color("AsaMutedSage"))
            }
            
            AsaButton(
                title: "ノードを追加",
                action: {
                    handleDoubleTap(at: CGPoint(x: 200, y: 300), in: nil)
                }
            )
            .frame(width: 150)
        }
        .animation(.easeInOut(duration: 0.5), value: viewModel.currentNodes.isEmpty)
    }
    
    // MARK: - Gestures
    
    private var simultaneousGestures: some Gesture {
        SimultaneousGesture(
            panGesture,
            magnificationGesture
        )
    }
    
    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                viewModel.isPanGestureActive = true
                let newOffset = CGSize(
                    width: lastOffsetValue.width + value.translation.width,
                    height: lastOffsetValue.height + value.translation.height
                )
                viewModel.updateCanvasTransform(offset: newOffset, scale: viewModel.canvasScale)
            }
            .onEnded { _ in
                lastOffsetValue = viewModel.canvasOffset
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.isPanGestureActive = false
                }
            }
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = lastScaleValue * value
                viewModel.updateCanvasTransform(offset: viewModel.canvasOffset, scale: newScale)
            }
            .onEnded { _ in
                lastScaleValue = viewModel.canvasScale
            }
    }
    
    // MARK: - Actions
    
    private func handleDoubleTap(at location: CGPoint, in geometry: GeometryProxy?) {
        let canvasLocation = geometry?.frame(in: .local).contains(location) == true ? location : CGPoint(x: 200, y: 300)
        tapLocation = canvasLocation
        showAddNodeSheet = true
    }
    
    private func dismissSelection() {
        viewModel.selectedNodeId = nil
        if viewModel.isConnecting {
            viewModel.cancelConnection()
        }
    }
}

// MARK: - AddNodeSheet

struct AddNodeSheet: View {
    @Bindable var viewModel: MindMapViewModel
    let position: CGPoint
    @Binding var isPresented: Bool
    
    @State private var nodeText = ""
    @State private var selectedColor: NodeColor = .asaCoffeeBrown
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // ヘッダー
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(selectedColor.color)
                    
                    Text("新しいノードを追加")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaDarkSlate"))
                }
                .padding(.top)
                
                // テキスト入力
                AsaCard {
                    VStack(spacing: 16) {
                        TextField("ノードのテキストを入力...", text: $nodeText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .focused($isTextFieldFocused)
                            .lineLimit(1...5)
                            .onSubmit {
                                addNode()
                            }
                        
                        // カラー選択
                        colorSelectionView
                    }
                    .padding()
                }
                
                // アクションボタン
                HStack(spacing: 16) {
                    AsaButton(
                        title: "キャンセル",
                        action: { isPresented = false },
                        color: Color("AsaMutedSage")
                    )
                    
                    AsaButton(
                        title: "追加",
                        action: addNode,
                        isEnabled: !nodeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isTextFieldFocused = true
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Color Selection View
    
    private var colorSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カラー")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 12) {
                ForEach(NodeColor.allCases, id: \.self) { color in
                    Button(action: {
                        selectedColor = color
                    }) {
                        Circle()
                            .fill(color.color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(
                                        Color.white,
                                        lineWidth: selectedColor == color ? 3 : 0
                                    )
                            )
                            .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                            .shadow(radius: selectedColor == color ? 4 : 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func addNode() {
        let trimmedText = nodeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let adjustedPosition = CGPoint(
            x: (position.x - viewModel.canvasOffset.width) / viewModel.canvasScale,
            y: (position.y - viewModel.canvasOffset.height) / viewModel.canvasScale
        )
        
        viewModel.addNode(text: trimmedText, position: adjustedPosition)
        
        // カラーを更新（ノードが作成された後）
        if let lastNode = viewModel.currentNodes.last {
            viewModel.updateNodeColor(nodeId: lastNode.id, color: selectedColor)
        }
        
        isPresented = false
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var viewModel = MindMapViewModel()
    
    return MindMapCanvasView(viewModel: viewModel)
}