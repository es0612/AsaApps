import SwiftUI

// MARK: - ConnectionView

struct ConnectionView: View {
    let viewModel: MindMapViewModel
    let connection: MindMapConnection
    let fromNode: MindMapNode
    let toNode: MindMapNode
    @State private var showDeleteButton = false
    
    var body: some View {
        Canvas { context, size in
            drawConnection(context: context, size: size)
        }
        .gesture(
            TapGesture()
                .onEnded {
                    toggleDeleteButton()
                }
        )
        .overlay(
            deleteButton,
            alignment: .center
        )
        .animation(.easeInOut(duration: 0.3), value: showDeleteButton)
    }
    
    // MARK: - Connection Drawing
    
    private func drawConnection(context: GraphicsContext, size: CGSize) {
        let fromPosition = viewModel.getDisplayPosition(for: fromNode.position)
        let toPosition = viewModel.getDisplayPosition(for: toNode.position)
        
        // ノードの中心点を計算（ノードサイズを考慮）
        let nodeRadius: CGFloat = 40
        let adjustedFromPosition = adjustPosition(fromPosition, towards: toPosition, offset: nodeRadius)
        let adjustedToPosition = adjustPosition(toPosition, towards: fromPosition, offset: nodeRadius)
        
        // ベジェ曲線のコントロールポイントを計算
        let controlPoint1 = calculateControlPoint(from: adjustedFromPosition, to: adjustedToPosition, isFirst: true)
        let controlPoint2 = calculateControlPoint(from: adjustedFromPosition, to: adjustedToPosition, isFirst: false)
        
        // パスを作成
        var path = Path()
        path.move(to: adjustedFromPosition)
        path.addCurve(
            to: adjustedToPosition,
            control1: controlPoint1,
            control2: controlPoint2
        )
        
        // 線を描画
        context.stroke(
            path,
            with: .color(connectionColor),
            style: connection.lineStyle.strokeStyle
        )
        
        // 矢印を描画
        drawArrow(context: context, at: adjustedToPosition, angle: angleToTarget(from: controlPoint2, to: adjustedToPosition))
    }
    
    // MARK: - Arrow Drawing
    
    private func drawArrow(context: GraphicsContext, at position: CGPoint, angle: Double) {
        let arrowLength: CGFloat = 12
        let arrowAngle: Double = .pi / 6 // 30度
        
        var arrowPath = Path()
        
        // 矢印の左の線
        let leftPoint = CGPoint(
            x: position.x - arrowLength * cos(angle - arrowAngle),
            y: position.y - arrowLength * sin(angle - arrowAngle)
        )
        
        // 矢印の右の線
        let rightPoint = CGPoint(
            x: position.x - arrowLength * cos(angle + arrowAngle),
            y: position.y - arrowLength * sin(angle + arrowAngle)
        )
        
        arrowPath.move(to: leftPoint)
        arrowPath.addLine(to: position)
        arrowPath.addLine(to: rightPoint)
        
        context.stroke(
            arrowPath,
            with: .color(connectionColor),
            style: StrokeStyle(lineWidth: 2, lineCap: .round)
        )
    }
    
    // MARK: - Delete Button
    
    private var deleteButton: some View {
        Group {
            if showDeleteButton {
                Button(action: deleteConnection) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                        .background(Circle().fill(Color.white))
                        .shadow(radius: 2)
                }
                .position(midPoint)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func adjustPosition(_ position: CGPoint, towards target: CGPoint, offset: CGFloat) -> CGPoint {
        let dx = target.x - position.x
        let dy = target.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        guard distance > 0 else { return position }
        
        let ratio = offset / distance
        return CGPoint(
            x: position.x + dx * ratio,
            y: position.y + dy * ratio
        )
    }
    
    private func calculateControlPoint(from: CGPoint, to: CGPoint, isFirst: Bool) -> CGPoint {
        let midX = (from.x + to.x) / 2
        let midY = (from.y + to.y) / 2
        
        let dx = to.x - from.x
        let dy = to.y - from.y
        let distance = sqrt(dx * dx + dy * dy)
        
        // 曲線の強度を距離に基づいて調整
        let curveStrength = min(distance * 0.3, 100)
        
        // 垂直方向のオフセット
        let offsetX = -dy / distance * curveStrength * (isFirst ? 0.5 : -0.5)
        let offsetY = dx / distance * curveStrength * (isFirst ? 0.5 : -0.5)
        
        return CGPoint(
            x: midX + offsetX,
            y: midY + offsetY
        )
    }
    
    private func angleToTarget(from: CGPoint, to: CGPoint) -> Double {
        let dx = to.x - from.x
        let dy = to.y - from.y
        return atan2(dy, dx)
    }
    
    // MARK: - Computed Properties
    
    private var connectionColor: Color {
        Color("AsaDarkSlate").opacity(0.7)
    }
    
    private var midPoint: CGPoint {
        let fromPosition = viewModel.getDisplayPosition(for: fromNode.position)
        let toPosition = viewModel.getDisplayPosition(for: toNode.position)
        
        return CGPoint(
            x: (fromPosition.x + toPosition.x) / 2,
            y: (fromPosition.y + toPosition.y) / 2
        )
    }
    
    // MARK: - Actions
    
    private func toggleDeleteButton() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showDeleteButton.toggle()
        }
        
        // 3秒後に自動的に非表示
        if showDeleteButton {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDeleteButton = false
                }
            }
        }
    }
    
    private func deleteConnection() {
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.deleteConnection(withId: connection.id)
        }
    }
}

// MARK: - ConnectionsLayer

struct ConnectionsLayer: View {
    let viewModel: MindMapViewModel
    
    var body: some View {
        ZStack {
            ForEach(viewModel.currentConnections) { connection in
                if let fromNode = getNode(withId: connection.fromNodeId),
                   let toNode = getNode(withId: connection.toNodeId) {
                    ConnectionView(
                        viewModel: viewModel,
                        connection: connection,
                        fromNode: fromNode,
                        toNode: toNode
                    )
                }
            }
            
            // 接続中のプレビューライン
            if viewModel.isConnecting,
               let fromNodeId = viewModel.connectingFromNodeId,
               let fromNode = getNode(withId: fromNodeId) {
                ConnectionPreview(viewModel: viewModel, fromNode: fromNode)
            }
        }
    }
    
    private func getNode(withId id: UUID) -> MindMapNode? {
        viewModel.currentNodes.first { $0.id == id }
    }
}

// MARK: - ConnectionPreview

struct ConnectionPreview: View {
    let viewModel: MindMapViewModel
    let fromNode: MindMapNode
    @State private var mousePosition = CGPoint.zero
    
    var body: some View {
        Canvas { context, size in
            let fromPosition = viewModel.getDisplayPosition(for: fromNode.position)
            
            var path = Path()
            path.move(to: fromPosition)
            path.addLine(to: mousePosition)
            
            context.stroke(
                path,
                with: .color(Color.yellow.opacity(0.6)),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 3])
            )
        }
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                mousePosition = location
            case .ended:
                break
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var viewModel = MindMapViewModel()
    
    return ZStack {
        Color("AsaSoftCream")
            .ignoresSafeArea()
        
        ConnectionsLayer(viewModel: viewModel)
    }
}