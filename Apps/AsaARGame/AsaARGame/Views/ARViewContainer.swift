import SwiftUI
import RealityKit
import ARKit

// MARK: - ARViewContainer
/// ARViewをSwiftUIで使用するためのラッパー
struct ARViewContainer: UIViewRepresentable {
    let viewModel: ARGameViewModel

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // ViewModelにARViewを設定
        Task { @MainActor in
            viewModel.arView = arView
        }

        // ARSessionの設定
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic

        arView.session.run(configuration)

        // セッションデリゲートを設定
        arView.session.delegate = context.coordinator

        // タップジェスチャーを追加
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)

        // コーチングオーバーレイを設定
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(coachingOverlay)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // 必要に応じて更新処理
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, ARSessionDelegate {
        let viewModel: ARGameViewModel

        init(viewModel: ARGameViewModel) {
            self.viewModel = viewModel
        }

        // MARK: - Tap Handling

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }

            let location = recognizer.location(in: arView)

            Task { @MainActor in
                viewModel.handleTap(at: location)
            }
        }

        // MARK: - ARSessionDelegate

        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            Task { @MainActor in
                viewModel.updateARSessionState(camera.trackingState)
            }
        }

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                if anchor is ARPlaneAnchor {
                    Task { @MainActor in
                        viewModel.onPlaneDetected()
                    }
                    break
                }
            }
        }

        func session(_ session: ARSession, didFailWithError error: Error) {
            Task { @MainActor in
                viewModel.errorMessage = "ARセッションエラー: \(error.localizedDescription)"
            }
        }

        func sessionWasInterrupted(_ session: ARSession) {
            Task { @MainActor in
                if viewModel.gameState == .playing {
                    viewModel.pauseGame()
                }
            }
        }

        func sessionInterruptionEnded(_ session: ARSession) {
            // セッション再開時の処理
        }
    }
}
