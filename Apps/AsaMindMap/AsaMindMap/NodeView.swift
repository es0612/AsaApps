import SwiftUI

// MARK: - NodeView

struct NodeView: View {
    @Bindable var viewModel: MindMapViewModel
    let node: MindMapNode
    @State private var dragOffset = CGSize.zero
    @State private var editingText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        nodeContent
            .position(nodePosition)
            .scaleEffect(viewModel.canvasScale)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !viewModel.isPanGestureActive {
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        if !viewModel.isPanGestureActive {
                            let newPosition = CGPoint(
                                x: node.position.x + value.translation.width / viewModel.canvasScale,
                                y: node.position.y + value.translation.height / viewModel.canvasScale
                            )
                            viewModel.updateNodePosition(nodeId: node.id, position: newPosition)
                            dragOffset = .zero
                        }
                    }
            )
            .animation(.easeInOut(duration: 0.2), value: dragOffset)
            .animation(.easeInOut(duration: 0.2), value: viewModel.selectedNodeId == node.id)
    }
    
    // MARK: - Node Content
    
    private var nodeContent: some View {
        Group {
            if node.isEditing {
                editingView
            } else {
                displayView
            }
        }
        .offset(dragOffset)
    }
    
    // MARK: - Display View
    
    private var displayView: some View {
        AsaCard {
            VStack(spacing: 8) {
                Text(node.displayText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                
                if isSelected {
                    nodeActionButtons
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(node.color.color)
                .shadow(
                    color: node.color.color.opacity(0.3),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: 2
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    Color.white.opacity(isSelected ? 0.8 : 0.0),
                    lineWidth: 2
                )
        )
        .overlay(
            connectionIndicator,
            alignment: .topTrailing
        )
        .onTapGesture {
            handleTap()
        }
        .onLongPressGesture {
            handleLongPress()
        }
    }
    
    // MARK: - Editing View
    
    private var editingView: some View {
        AsaCard {
            VStack(spacing: 12) {
                TextField("ノードテキスト", text: $editingText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        finishEditing()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                
                HStack(spacing: 12) {
                    AsaButton(
                        title: "完了",
                        action: finishEditing,
                        color: Color("AsaMutedSage")
                    )
                    .frame(width: 60, height: 32)
                    
                    AsaButton(
                        title: "削除",
                        action: deleteNode,
                        color: Color.red
                    )
                    .frame(width: 60, height: 32)
                }
                .font(.system(size: 12))
            }
            .padding(8)
        }
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(node.color.color)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            editingText = node.text
            isTextFieldFocused = true
        }
    }
    
    // MARK: - Node Action Buttons
    
    private var nodeActionButtons: some View {
        HStack(spacing: 8) {
            Button(action: {
                viewModel.toggleNodeEditing(nodeId: node.id)
            }) {
                Image(systemName: "pencil")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Circle().fill(Color.white.opacity(0.2)))
            }
            
            Button(action: {
                startConnection()
            }) {
                Image(systemName: "link")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Circle().fill(Color.white.opacity(0.2)))
            }
            
            colorPicker
        }
    }
    
    // MARK: - Color Picker
    
    private var colorPicker: some View {
        Menu {
            ForEach(NodeColor.allCases, id: \.self) { color in
                Button(action: {
                    viewModel.updateNodeColor(nodeId: node.id, color: color)
                }) {
                    HStack {
                        Circle()
                            .fill(color.color)
                            .frame(width: 16, height: 16)
                        Text(color.displayName)
                        if node.color == color {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "paintbrush")
                .font(.system(size: 12))
                .foregroundColor(.white)
                .padding(4)
                .background(Circle().fill(Color.white.opacity(0.2)))
        }
    }
    
    // MARK: - Connection Indicator
    
    private var connectionIndicator: some View {
        Group {
            if viewModel.connectingFromNodeId == node.id {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 12, height: 12)
                    .offset(x: 4, y: -4)
                    .scaleEffect(viewModel.isConnecting ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: viewModel.isConnecting)
            } else if viewModel.isConnecting && viewModel.connectingFromNodeId != node.id {
                Circle()
                    .fill(Color.green.opacity(0.7))
                    .frame(width: 10, height: 10)
                    .offset(x: 4, y: -4)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isSelected: Bool {
        viewModel.selectedNodeId == node.id
    }
    
    private var nodePosition: CGPoint {
        CGPoint(
            x: node.position.x + viewModel.canvasOffset.width,
            y: node.position.y + viewModel.canvasOffset.height
        )
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        if viewModel.isConnecting && viewModel.connectingFromNodeId != node.id {
            viewModel.completeConnection(toNodeId: node.id)
        } else {
            viewModel.selectedNodeId = (viewModel.selectedNodeId == node.id) ? nil : node.id
        }
    }
    
    private func handleLongPress() {
        if !viewModel.isConnecting {
            startConnection()
        }
    }
    
    private func startConnection() {
        if viewModel.isConnecting {
            viewModel.cancelConnection()
        } else {
            viewModel.startConnecting(fromNodeId: node.id)
        }
    }
    
    private func finishEditing() {
        let trimmedText = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            viewModel.updateNodeText(nodeId: node.id, text: trimmedText)
        }
        viewModel.toggleNodeEditing(nodeId: node.id)
        isTextFieldFocused = false
    }
    
    private func deleteNode() {
        viewModel.deleteNode(withId: node.id)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var viewModel = MindMapViewModel()
    
    return ZStack {
        Color("AsaSoftCream")
            .ignoresSafeArea()
        
        if let sampleNode = MindMapNode.sampleNodes.first {
            NodeView(viewModel: viewModel, node: sampleNode)
        }
    }
}