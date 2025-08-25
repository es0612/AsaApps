import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @State private var viewModel = MindMapViewModel()
    @State private var showNewMindMapSheet = false
    @State private var showMindMapList = false
    @State private var showClearAlert = false
    @State private var showResetViewAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MARK: - Mind Map Canvas
                mindMapCanvas
                
                // MARK: - Status Bar
                statusBar
            }
            .navigationTitle(currentMindMapTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    mindMapSelectionButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarMenu
                }
            }
            .alert("マインドマップをクリア", isPresented: $showClearAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("クリア", role: .destructive) {
                    viewModel.clearCurrentMindMap()
                }
            } message: {
                Text("現在のマインドマップのすべてのノードと接続が削除されます。この操作は元に戻せません。")
            }
            .alert("ビューをリセット", isPresented: $showResetViewAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("リセット") {
                    viewModel.resetCanvasTransform()
                }
            } message: {
                Text("ズームとパン位置をリセットしますか？")
            }
            .sheet(isPresented: $showNewMindMapSheet) {
                NewMindMapSheet(viewModel: viewModel, isPresented: $showNewMindMapSheet)
            }
            .sheet(isPresented: $showMindMapList) {
                MindMapListSheet(viewModel: viewModel, isPresented: $showMindMapList)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color("AsaSoftCream").opacity(0.1),
                        Color("AsaDarkSlate").opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
    
    // MARK: - Mind Map Canvas
    
    private var mindMapCanvas: some View {
        MindMapCanvasView(viewModel: viewModel)
            .onTapGesture {
                // 接続モードをキャンセル
                if viewModel.isConnecting {
                    viewModel.cancelConnection()
                }
            }
    }
    
    // MARK: - Status Bar
    
    private var statusBar: some View {
        AsaCard {
            HStack {
                // 統計情報
                statsSection
                
                Spacer()
                
                // 接続中の表示
                if viewModel.isConnecting {
                    connectionStatusView
                } else {
                    // キャンバスコントロール
                    canvasControls
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color("AsaDarkSlate").opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ノード: \(viewModel.currentNodeCount)")
                    .font(.caption)
                    .foregroundColor(Color("AsaDarkSlate"))
                Text("接続: \(viewModel.currentConnectionCount)")
                    .font(.caption2)
                    .foregroundColor(Color("AsaMutedSage"))
            }
            
            Text("🧠")
                .font(.title2)
        }
    }
    
    // MARK: - Connection Status View
    
    private var connectionStatusView: some View {
        HStack(spacing: 12) {
            Image(systemName: "link")
                .foregroundColor(.yellow)
                .scaleEffect(1.2)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: viewModel.isConnecting)
            
            Text("接続先を選択してください")
                .font(.caption)
                .foregroundColor(Color("AsaDarkSlate"))
            
            AsaButton(
                title: "キャンセル",
                action: { viewModel.cancelConnection() },
                color: Color("AsaMutedSage")
            )
            .frame(width: 80, height: 24)
        }
    }
    
    // MARK: - Canvas Controls
    
    private var canvasControls: some View {
        HStack(spacing: 8) {
            // ズーム表示
            Text("×\(String(format: "%.1f", viewModel.canvasScale))")
                .font(.caption2)
                .foregroundColor(Color("AsaMutedSage"))
                .frame(minWidth: 30)
            
            Button(action: {
                showResetViewAlert = true
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14))
                    .foregroundColor(Color("AsaDarkSlate"))
            }
        }
    }
    
    // MARK: - Mind Map Selection Button
    
    private var mindMapSelectionButton: some View {
        Button(action: {
            showMindMapList = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 16))
                Text("\(viewModel.mindMapCount)")
                    .font(.caption)
            }
            .foregroundColor(Color("AsaCoffeeBrown"))
        }
    }
    
    // MARK: - Toolbar Menu
    
    private var toolbarMenu: some View {
        Menu {
            Button(action: {
                showNewMindMapSheet = true
            }) {
                Label("新しいマインドマップ", systemImage: "plus.circle")
            }
            
            Divider()
            
            Button(action: {
                showClearAlert = true
            }) {
                Label("現在のマップをクリア", systemImage: "trash")
            }
            
            Button(action: {
                showResetViewAlert = true
            }) {
                Label("ビューをリセット", systemImage: "arrow.counterclockwise")
            }
            
            Divider()
            
            Button(action: {}) {
                Label("使い方", systemImage: "questionmark.circle")
            }
            
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(Color("AsaCoffeeBrown"))
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentMindMapTitle: String {
        viewModel.currentMindMap?.title ?? "AsaMindMap"
    }
}

// MARK: - NewMindMapSheet

struct NewMindMapSheet: View {
    @Bindable var viewModel: MindMapViewModel
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var centralNodeText = ""
    @FocusState private var isTitleFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // ヘッダー
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50))
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Text("新しいマインドマップ")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaDarkSlate"))
                }
                .padding(.top)
                
                // 入力フィールド
                AsaCard {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("タイトル")
                                .font(.headline)
                                .foregroundColor(Color("AsaDarkSlate"))
                            
                            TextField("マインドマップのタイトル", text: $title)
                                .textFieldStyle(.roundedBorder)
                                .focused($isTitleFieldFocused)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("中心ノード")
                                .font(.headline)
                                .foregroundColor(Color("AsaDarkSlate"))
                            
                            TextField("中心となるアイデア", text: $centralNodeText)
                                .textFieldStyle(.roundedBorder)
                        }
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
                        title: "作成",
                        action: createMindMap,
                        isEnabled: !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isTitleFieldFocused = true
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func createMindMap() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else { return }
        
        viewModel.createNewMindMap(title: trimmedTitle)
        
        isPresented = false
    }
}

// MARK: - MindMapListSheet

struct MindMapListSheet: View {
    @Bindable var viewModel: MindMapViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.mindMaps) { mindMap in
                    MindMapRowView(
                        mindMap: mindMap,
                        isSelected: viewModel.currentMindMap?.id == mindMap.id,
                        onSelect: {
                            viewModel.selectMindMap(mindMap)
                            isPresented = false
                        }
                    )
                }
                .onDelete(perform: deleteMindMaps)
            }
            .navigationTitle("マインドマップ一覧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        isPresented = false
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func deleteMindMaps(offsets: IndexSet) {
        for index in offsets {
            let mindMap = viewModel.mindMaps[index]
            viewModel.deleteMindMap(withId: mindMap.id)
        }
    }
}

// MARK: - MindMapRowView

struct MindMapRowView: View {
    let mindMap: MindMap
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            AsaCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(mindMap.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                        }
                    }
                    
                    HStack {
                        Text("ノード: \(mindMap.nodeCount)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("接続: \(mindMap.connectionCount)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text(mindMap.formattedModifiedTime)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color("AsaCoffeeBrown") : Color("AsaMocha"))
                    .shadow(radius: isSelected ? 6 : 3)
            )
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}