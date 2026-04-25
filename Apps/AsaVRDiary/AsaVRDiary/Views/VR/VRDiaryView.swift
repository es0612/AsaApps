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
    @State private var showingHint: Bool = !UserDefaults.standard.bool(forKey: Self.hintDismissedKey)

    private static let hintDismissedKey = "AsaVRDiary_VRHintDismissed_v1"

    var body: some View {
        ZStack {
            // VR空間の雰囲気を出す夜空グラデーション
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.18),
                    Color(red: 0.10, green: 0.06, blue: 0.24),
                    Color(red: 0.02, green: 0.02, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

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

                // 操作ヒント（初回のみ）
                if showingHint {
                    hintOverlay
                        .padding(.top, 8)
                }

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

    /// 操作ヒント
    private var hintOverlay: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.tap.fill")
                .font(.subheadline)
                .foregroundStyle(.white)

            Text("カードをタップで選択 ・ ピンチ/ドラッグで視点変更")
                .font(.caption)
                .foregroundStyle(.white)

            Button {
                dismissHint()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(Capsule())
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                if showingHint {
                    dismissHint()
                }
            }
        }
    }

    private func dismissHint() {
        UserDefaults.standard.set(true, forKey: Self.hintDismissedKey)
        withAnimation(.easeOut(duration: 0.4)) {
            showingHint = false
        }
    }

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

        // 背景は SwiftUI 側のグラデーションを見せるため透明化
        arView.environment.background = .color(.clear)
        arView.backgroundColor = .clear

        // カメラセットアップ（軌道カメラ方式）
        // FOV 80° は portrait アスペクトでも水平に十分な可視範囲を確保するため
        let cameraAnchor = AnchorEntity(world: .zero)
        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = 80
        cameraAnchor.addChild(camera)
        arView.scene.addAnchor(cameraAnchor)

        context.coordinator.cameraEntity = camera
        context.coordinator.cameraAnchor = cameraAnchor

        // 初期カメラ位置を即座に適用
        Self.applyCameraTransform(to: camera, viewModel: vrViewModel, animated: false)

        // コンテンツシーンを構築（entries が空でもアンカーは作る）
        let contentAnchor = vrViewModel.buildScene(entries: diaryViewModel.filteredEntries)
        arView.scene.addAnchor(contentAnchor)
        context.coordinator.contentAnchor = contentAnchor
        // シーン追加後にアニメーション開始（buildScene 内で move() するとアニメシステムが動かないため）
        if !diaryViewModel.filteredEntries.isEmpty {
            vrViewModel.sceneService.startEntranceAnimations()
        }

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

        // パンジェスチャー（左右ドラッグで回転、上下で高さ調整）
        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        arView.addGestureRecognizer(panGesture)

        context.coordinator.arView = arView

        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        // entries が後から populate されるケースに対応するため、
        // 描画済みエンティティ数と現在の entries 数を比較して再構築判定
        let currentEntries = diaryViewModel.filteredEntries
        let renderedCount = vrViewModel.sceneService.entities.count
        let needsRebuild = vrViewModel.needsSceneUpdate || renderedCount != currentEntries.count

        if needsRebuild {
            if let oldContent = context.coordinator.contentAnchor {
                arView.scene.removeAnchor(oldContent)
            }
            let newContent = vrViewModel.buildScene(entries: currentEntries)
            arView.scene.addAnchor(newContent)
            context.coordinator.contentAnchor = newContent
            // シーン追加後にアニメーション発火
            if !currentEntries.isEmpty {
                vrViewModel.sceneService.startEntranceAnimations()
            }
            vrViewModel.markSceneUpdated()
        }

        // カメラ更新（zoomLevel/rotationAngle/cameraOffset を参照することで
        // @Observable の変更検知 → updateUIView 再呼び出しが起きる）
        if let camera = context.coordinator.cameraEntity {
            Self.applyCameraTransform(to: camera, viewModel: vrViewModel, animated: true)
        }
    }

    /// オービタルカメラの transform を計算して適用
    /// - 中心 = `cameraOffset` + grid 中心オフセット を look-at ターゲット
    /// - 距離 = baseDistance / zoomLevel
    /// - Y軸回転 = rotationAngle
    /// - 高さ = カメラオフセット.y + 一定オフセット
    @MainActor
    private static func applyCameraTransform(
        to camera: PerspectiveCamera,
        viewModel: VRSceneViewModel,
        animated: Bool
    ) {
        let baseDistance: Float = 1.0
        let distance = baseDistance / max(viewModel.zoomLevel, 0.1)
        let angle = viewModel.rotationAngle
        // grid center が y=-0.13 付近、z=-0.5 付近なので look-at をそこに合わせる
        let lookAtPoint = SIMD3<Float>(
            viewModel.cameraOffset.x,
            viewModel.cameraOffset.y - 0.13,
            viewModel.cameraOffset.z - 0.5
        )
        let cameraPos = SIMD3<Float>(
            sin(angle) * distance + viewModel.cameraOffset.x,
            0.0 + viewModel.cameraOffset.y,
            cos(angle) * distance + viewModel.cameraOffset.z - 0.5
        )

        if animated {
            // 一時 Entity で look-at transform を計算して move(to:) で補間適用
            let temp = Entity()
            temp.look(at: lookAtPoint, from: cameraPos, relativeTo: nil)
            camera.move(
                to: temp.transform,
                relativeTo: nil,
                duration: 0.3,
                timingFunction: .easeInOut
            )
        } else {
            camera.look(at: lookAtPoint, from: cameraPos, relativeTo: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(diaryViewModel: diaryViewModel, vrViewModel: vrViewModel)
    }

    class Coordinator: NSObject {
        var diaryViewModel: DiaryViewModel
        var vrViewModel: VRSceneViewModel
        weak var arView: ARView?
        weak var cameraEntity: PerspectiveCamera?
        weak var cameraAnchor: AnchorEntity?
        weak var contentAnchor: AnchorEntity?

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

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView = arView else { return }
            if gesture.state == .changed {
                let translation = gesture.translation(in: arView)
                // 横方向 → Y軸回転、縦方向 → カメラ高さ調整
                let rotationDelta = Float(translation.x) * 0.005
                let heightDelta = Float(-translation.y) * 0.001
                Task { @MainActor in
                    self.vrViewModel.rotationAngle += rotationDelta
                    let currentOffset = self.vrViewModel.cameraOffset
                    self.vrViewModel.cameraOffset = SIMD3<Float>(
                        currentOffset.x,
                        max(min(currentOffset.y + heightDelta, 0.5), -0.5),
                        currentOffset.z
                    )
                }
                gesture.setTranslation(.zero, in: arView)
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
