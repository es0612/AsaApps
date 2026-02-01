//
//  VRDiaryView.swift
//  AsaVRDiary
//
//  VR空間での日記表示画面
//

import SwiftUI
import RealityKit

/// VR空間での日記表示画面
struct VRDiaryView: View {
    @Bindable var diaryViewModel: DiaryViewModel
    @Bindable var vrViewModel: VRSceneViewModel
    @State private var showingControlPanel = true
    @State private var showingDetailSheet = false

    var body: some View {
        ZStack {
            // RealityKit シーン（ARViewベース）
            RealityKitSceneView(
                diaryViewModel: diaryViewModel,
                vrViewModel: vrViewModel
            )
            .edgesIgnoringSafeArea(.all)

            // オーバーレイUI
            VStack {
                // トップバー
                topBar

                Spacer()

                // 選択中のエントリー情報
                if let selectedId = vrViewModel.selectedEntryId,
                   let entry = diaryViewModel.entries.first(where: { $0.id == selectedId }) {
                    selectedEntryOverlay(entry: entry)
                }

                // コントロールパネル
                if showingControlPanel {
                    controlPanel
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingDetailSheet) {
            if let selectedId = vrViewModel.selectedEntryId,
               let entry = diaryViewModel.entries.first(where: { $0.id == selectedId }) {
                DiaryDetailView(entry: entry, viewModel: diaryViewModel)
            }
        }
        .onAppear {
            diaryViewModel.loadEntries()
        }
    }

    // MARK: - Subviews

    /// トップバー
    private var topBar: some View {
        HStack {
            // 表示モード切り替え
            Menu {
                ForEach(VRSceneService.DisplayMode.allCases, id: \.self) { mode in
                    Button {
                        vrViewModel.switchDisplayMode(to: mode, entries: diaryViewModel.filteredEntries)
                    } label: {
                        Label(mode.displayName, systemImage: mode.icon)
                    }
                }
            } label: {
                Label(vrViewModel.displayMode.displayName, systemImage: vrViewModel.displayMode.icon)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }

            Spacer()

            // エントリー数
            Text("\(diaryViewModel.filteredEntries.count)件の日記")
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())

            // コントロールパネル表示切り替え
            Button {
                withAnimation {
                    showingControlPanel.toggle()
                }
            } label: {
                Image(systemName: showingControlPanel ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
    }

    /// 選択中エントリーのオーバーレイ
    private func selectedEntryOverlay(entry: DiaryEntry) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(entry.mood.emoji)
                    .font(.title)
                Text(entry.title)
                    .font(.headline)
                Spacer()
                Button {
                    showingDetailSheet = true
                } label: {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.title2)
                }
            }

            HStack {
                CategoryBadge(category: entry.category)
                Text(entry.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("フリップ") {
                    vrViewModel.flipEntry(entry.id)
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    /// コントロールパネル
    private var controlPanel: some View {
        VStack(spacing: 16) {
            // ズームコントロール
            HStack(spacing: 20) {
                Button {
                    vrViewModel.zoomOut()
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.title2)
                }

                Text(String(format: "%.1fx", vrViewModel.zoomLevel))
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .frame(width: 40)

                Button {
                    vrViewModel.zoomIn()
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.title2)
                }
            }

            // 回転コントロール
            HStack(spacing: 20) {
                Button {
                    vrViewModel.rotateLeft()
                } label: {
                    Image(systemName: "rotate.left")
                        .font(.title2)
                }

                Button {
                    vrViewModel.resetCamera()
                } label: {
                    Image(systemName: "viewfinder")
                        .font(.title2)
                }

                Button {
                    vrViewModel.rotateRight()
                } label: {
                    Image(systemName: "rotate.right")
                        .font(.title2)
                }
            }

            // カテゴリフィルター
            CategoryFilterPicker(selectedCategory: $diaryViewModel.selectedCategory)
                .onChange(of: diaryViewModel.selectedCategory) { _, _ in
                    vrViewModel.needsSceneUpdate = true
                }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - RealityKitSceneView

/// ARViewをラップしたUIViewRepresentable
struct RealityKitSceneView: UIViewRepresentable {
    @Bindable var diaryViewModel: DiaryViewModel
    @Bindable var vrViewModel: VRSceneViewModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // 非ARモード（カメラなし）で使用
        arView.cameraMode = .nonAR

        // 背景色を設定
        arView.environment.background = .color(.systemBackground)

        // シーンを構築
        let anchor = vrViewModel.buildScene(entries: diaryViewModel.filteredEntries)
        arView.scene.addAnchor(anchor)

        // タップジェスチャーを追加
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)

        // ピンチジェスチャーを追加
        let pinchGesture = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        arView.addGestureRecognizer(pinchGesture)

        context.coordinator.arView = arView

        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        // シーン更新が必要な場合
        if vrViewModel.needsSceneUpdate {
            // 既存のアンカーを削除
            arView.scene.anchors.removeAll()

            // 新しいシーンを構築
            let anchor = vrViewModel.buildScene(entries: diaryViewModel.filteredEntries)
            arView.scene.addAnchor(anchor)

            vrViewModel.markSceneUpdated()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(diaryViewModel: diaryViewModel, vrViewModel: vrViewModel)
    }

    class Coordinator: NSObject {
        var diaryViewModel: DiaryViewModel
        var vrViewModel: VRSceneViewModel
        weak var arView: ARView?

        init(diaryViewModel: DiaryViewModel, vrViewModel: VRSceneViewModel) {
            self.diaryViewModel = diaryViewModel
            self.vrViewModel = vrViewModel
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }

            let location = gesture.location(in: arView)
            let results = arView.hitTest(location)

            if let firstHit = results.first,
               let modelEntity = firstHit.entity as? ModelEntity,
               let cardComponent = modelEntity.components[DiaryCardComponent.self] {

                let entryId = cardComponent.entryId

                Task { @MainActor in
                    if self.vrViewModel.selectedEntryId == entryId {
                        // 既に選択中の場合はフリップ
                        self.vrViewModel.flipEntry(entryId)
                    } else {
                        // 新しく選択
                        self.vrViewModel.selectEntry(entryId)
                    }
                }
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            if gesture.state == .changed {
                let scale = Float(gesture.scale)
                Task { @MainActor in
                    let newZoom = self.vrViewModel.zoomLevel * scale
                    self.vrViewModel.zoomLevel = min(max(newZoom, 0.5), 3.0)
                }
                gesture.scale = 1.0
            }
        }
    }
}

#Preview {
    VRDiaryView(
        diaryViewModel: DiaryViewModel(),
        vrViewModel: VRSceneViewModel()
    )
}
