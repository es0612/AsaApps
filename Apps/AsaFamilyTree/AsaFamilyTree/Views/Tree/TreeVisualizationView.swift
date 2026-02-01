import SwiftUI
import AsaFamilyTreeKit
import AsaUIKit

struct TreeVisualizationView: View {
    // MARK: - Environment

    @Environment(FamilyTreeViewModel.self) private var viewModel

    // MARK: - State

    @State private var layoutEngine = TreeLayoutEngine()
    @State private var showingAddMemberSheet = false
    @State private var showingTreeSelector = false

    // MARK: - Computed Properties

    private var treeLayout: TreeLayout? {
        guard let tree = viewModel.currentTree else { return nil }
        return layoutEngine.calculateLayout(for: tree)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.appState == .loading {
                    ProgressView("読み込み中...")
                } else if let layout = treeLayout, !layout.nodes.isEmpty {
                    treeCanvas(layout: layout)
                } else if viewModel.currentTree != nil {
                    emptyTreeView
                }
            }
            .navigationTitle(viewModel.currentTree?.name ?? "家系図")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.familyTrees.count > 1 {
                        Button {
                            showingTreeSelector = true
                        } label: {
                            Image(systemName: "folder.fill")
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // ズームコントロール
                        Menu {
                            Button("ズームイン", systemImage: "plus.magnifyingglass") {
                                viewModel.zoomIn()
                            }
                            Button("ズームアウト", systemImage: "minus.magnifyingglass") {
                                viewModel.zoomOut()
                            }
                            Button("リセット", systemImage: "arrow.counterclockwise") {
                                viewModel.resetZoom()
                            }
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }

                        // メンバー追加ボタン
                        Button {
                            showingAddMemberSheet = true
                        } label: {
                            Image(systemName: "person.badge.plus")
                        }
                        .disabled(viewModel.currentTree == nil)
                    }
                }
            }
            .sheet(isPresented: $showingAddMemberSheet) {
                AddMemberSheet()
            }
            .sheet(isPresented: $showingTreeSelector) {
                TreeSelectorSheet()
            }
        }
    }

    // MARK: - Tree Canvas

    private func treeCanvas(layout: TreeLayout) -> some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                ZStack {
                    // 接続線
                    ForEach(layout.connections) { connection in
                        ConnectionLineView(connection: connection)
                    }

                    // ノード
                    ForEach(layout.nodes) { node in
                        MemberNodeView(node: node)
                            .position(node.center)
                            .onTapGesture {
                                selectMember(id: node.id)
                            }
                    }
                }
                .frame(
                    width: max(layout.bounds.width * viewModel.zoomScale, geometry.size.width),
                    height: max(layout.bounds.height * viewModel.zoomScale, geometry.size.height)
                )
                .scaleEffect(viewModel.zoomScale)
                .offset(viewModel.panOffset)
            }
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let newScale = max(0.3, min(3.0, viewModel.zoomScale * value))
                        viewModel.zoomScale = newScale
                    }
            )
        }
    }

    // MARK: - Empty Tree View

    private var emptyTreeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundStyle(AsaColors.mutedSage)

            Text("メンバーがいません")
                .font(.title3)
                .fontWeight(.medium)

            Text("家族メンバーを追加して\n家系図を作成しましょう")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: {
                showingAddMemberSheet = true
            }) {
                Label("メンバーを追加", systemImage: "person.badge.plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AsaColors.coffeeBrown)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }

    // MARK: - Helper Methods

    private func selectMember(id: UUID) {
        if let member = viewModel.currentTree?.members.first(where: { $0.id == id }) {
            viewModel.selectMember(member)
        }
    }
}

// MARK: - Connection Line View

struct ConnectionLineView: View {
    let connection: TreeConnection

    var body: some View {
        Path { path in
            path.move(to: connection.from)

            switch connection.connectionType {
            case .parentChild:
                // 階段状の接続線
                let midY = (connection.from.y + connection.to.y) / 2
                path.addLine(to: CGPoint(x: connection.from.x, y: midY))
                path.addLine(to: CGPoint(x: connection.to.x, y: midY))
                path.addLine(to: connection.to)

            case .spouse:
                // 直線
                path.addLine(to: connection.to)
            }
        }
        .stroke(
            Color(cgColor: connection.connectionType.lineColor),
            style: StrokeStyle(
                lineWidth: connection.connectionType.lineWidth,
                lineCap: .round,
                lineJoin: .round
            )
        )
    }
}

// MARK: - Tree Selector Sheet

struct TreeSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FamilyTreeViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            List(viewModel.familyTrees, id: \.id) { tree in
                Button {
                    viewModel.selectTree(tree)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(tree.name)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text("\(tree.memberCount)人のメンバー")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if tree.id == viewModel.currentTree?.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AsaColors.coffeeBrown)
                        }
                    }
                }
            }
            .navigationTitle("家系図を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TreeVisualizationView()
        .environment(FamilyTreeViewModel())
}
