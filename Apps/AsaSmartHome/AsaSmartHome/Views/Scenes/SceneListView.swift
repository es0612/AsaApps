import SwiftUI

// MARK: - SceneListView

/// シーン一覧画面
struct SceneListView: View {
    // MARK: - Properties

    @Bindable var viewModel: SmartHomeViewModel
    @State private var showAddScene = false
    @State private var editingScene: SmartScene?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // プリセットシーン
                    if !builtInScenes.isEmpty {
                        sceneSection(title: "プリセット", scenes: builtInScenes)
                    }

                    // カスタムシーン
                    if !customScenes.isEmpty {
                        sceneSection(title: "カスタム", scenes: customScenes)
                    }

                    // 空の状態
                    if viewModel.scenes.isEmpty {
                        emptyState
                    }
                }
                .padding()
            }
            .background(Color.asaDarkSlate)
            .navigationTitle("シーン")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.asaDarkSlate, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddScene = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.asaCoffeeBrown)
                    }
                }
            }
            .sheet(isPresented: $showAddScene) {
                SceneEditorSheet(viewModel: viewModel, scene: nil)
            }
            .sheet(item: $editingScene) { scene in
                SceneEditorSheet(viewModel: viewModel, scene: scene)
            }
        }
    }

    // MARK: - Computed Properties

    private var builtInScenes: [SmartScene] {
        viewModel.scenes.filter { $0.isBuiltIn }
    }

    private var customScenes: [SmartScene] {
        viewModel.scenes.filter { !$0.isBuiltIn }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func sceneSection(title: String, scenes: [SmartScene]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(scenes) { scene in
                    SceneCardView(
                        scene: scene,
                        onExecute: {
                            await viewModel.executeSmartScene(scene)
                        },
                        onEdit: {
                            editingScene = scene
                        },
                        onDelete: scene.isBuiltIn ? nil : {
                            await deleteScene(scene)
                        }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))

            Text("シーンがありません")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))

            Text("シーンを作成して、複数のデバイスを\n一括で操作しましょう")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            Button {
                showAddScene = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("シーンを作成")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.asaCoffeeBrown)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Private Methods

    private func deleteScene(_ scene: SmartScene) async {
        do {
            try await viewModel.deleteSmartScene(scene)
        } catch {
            print("Failed to delete scene: \(error)")
        }
    }
}

// MARK: - SceneCardView

struct SceneCardView: View {
    let scene: SmartScene
    let onExecute: () async -> Void
    let onEdit: () -> Void
    let onDelete: (() async -> Void)?

    @State private var isExecuting = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 16) {
            // アイコン
            ZStack {
                Circle()
                    .fill(Color(hex: scene.colorHex).opacity(0.2))
                    .frame(width: 56, height: 56)

                if isExecuting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: scene.iconName)
                        .font(.system(size: 24))
                        .foregroundStyle(Color(hex: scene.colorHex))
                }
            }

            // シーン名
            Text(scene.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(1)

            // アクション数
            Text("\(scene.actions.count)アクション")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: scene.colorHex).opacity(0.3), lineWidth: 1)
        )
        .contextMenu {
            Button {
                executeScene()
            } label: {
                Label("実行", systemImage: "play.fill")
            }

            Button {
                onEdit()
            } label: {
                Label("編集", systemImage: "pencil")
            }

            if let onDelete = onDelete {
                Divider()

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("削除", systemImage: "trash")
                }
            }
        }
        .onTapGesture {
            executeScene()
        }
        .confirmationDialog(
            "シーンを削除",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                if let onDelete = onDelete {
                    Task {
                        await onDelete()
                    }
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("「\(scene.name)」を削除しますか？")
        }
    }

    private func executeScene() {
        isExecuting = true
        Task {
            await onExecute()
            try? await Task.sleep(nanoseconds: 500_000_000)  // 視覚的フィードバック
            isExecuting = false
        }
    }
}

// MARK: - SceneEditorSheet

struct SceneEditorSheet: View {
    @Bindable var viewModel: SmartHomeViewModel
    let scene: SmartScene?
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    @State private var isLoading = false

    init(viewModel: SmartHomeViewModel, scene: SmartScene?) {
        self.viewModel = viewModel
        self.scene = scene
        self._name = State(initialValue: scene?.name ?? "")
        self._selectedIcon = State(initialValue: scene?.iconName ?? "star.fill")
        self._selectedColor = State(initialValue: scene?.colorHex ?? "C68C53")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("シーン名") {
                    TextField("例: おやすみ", text: $name)
                }

                Section("アイコン") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(SceneEditorViewModel.availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColor) : .secondary)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.2) : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("カラー") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(SceneEditorViewModel.availableColors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(scene == nil ? "新規シーン" : "シーンを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveScene()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }
            }
        }
    }

    private func saveScene() {
        isLoading = true
        Task {
            do {
                if let existingScene = scene {
                    existingScene.name = name.trimmingCharacters(in: .whitespaces)
                    existingScene.iconName = selectedIcon
                    existingScene.colorHex = selectedColor
                    try await viewModel.updateSmartScene(existingScene)
                } else {
                    let newScene = SmartScene(
                        name: name.trimmingCharacters(in: .whitespaces),
                        iconName: selectedIcon,
                        colorHex: selectedColor
                    )
                    try await viewModel.addSmartScene(newScene)
                }
                dismiss()
            } catch {
                print("Failed to save scene: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - Preview

#Preview("Scene List") {
    Text("Scene List Preview")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.asaDarkSlate)
}
