import Foundation
import ARKit
import RealityKit
import Combine

// MARK: - ARGameViewModel
/// ゲーム全体の状態とARセッションを管理
@Observable @MainActor
final class ARGameViewModel {
    // MARK: - Game Constants

    private enum Constants {
        static let gameDuration: TimeInterval = 60.0
        static let targetLifespan: TimeInterval = 3.0
        static let spawnInterval: TimeInterval = 1.5
    }

    // MARK: - Game State Properties

    /// ゲーム状態
    var gameState: GameState = .idle

    /// スコア
    var score: GameScore = GameScore()

    /// 残り時間
    var remainingTime: TimeInterval = Constants.gameDuration

    /// ハイスコア
    var highScore: Int = GameScore.loadHighScore()

    // MARK: - AR State Properties

    /// ARView参照
    var arView: ARView?

    /// 平面検出済みかどうか
    var isPlaneDetected = false

    /// ARセッション状態
    var arSessionState: ARCamera.TrackingState = .notAvailable

    /// エラーメッセージ
    var errorMessage: String?

    /// ガイドメッセージ
    var guideMessage: String?

    // MARK: - UI State Properties

    /// オンボーディング表示中
    var showingOnboarding = false

    /// ゲームオーバー画面表示中
    var showingGameOver = false

    /// 一時停止メニュー表示中
    var showingPauseMenu = false

    // MARK: - Internal Properties

    /// ゲームアンカー
    private var gameAnchor: AnchorEntity?

    /// ターゲットレンダラー
    private let targetRenderer = TargetRenderer()

    /// ターゲット出現システム
    private let spawnSystem = TargetSpawnSystem()

    /// アクティブなターゲットEntityとIDのマッピング
    private var activeTargets: [UUID: Entity] = [:]

    /// ゲームタイマー
    private var gameTimer: Timer?

    /// 更新タイマー（フレーム更新用）
    private var updateTimer: Timer?

    /// オンボーディング完了フラグ
    var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: "AsaARGame_HasCompletedOnboarding")
    }

    // MARK: - Initialization

    init() {
        setupSystems()
        checkAndShowOnboarding()
    }

    // MARK: - Setup

    private func setupSystems() {
        // 出現システムの設定
        spawnSystem.targetRenderer = targetRenderer
        spawnSystem.onTargetSpawned = { [weak self] target, entity in
            self?.onTargetSpawned(target: target, entity: entity)
        }
    }

    private func checkAndShowOnboarding() {
        if !hasCompletedOnboarding {
            showingOnboarding = true
        }
    }

    // MARK: - AR Setup

    func setupAR() {
        guard ARWorldTrackingConfiguration.isSupported else {
            errorMessage = "このデバイスはAR機能をサポートしていません"
            gameState = .idle
            return
        }

        gameState = .waitingForPlane
        updateGuideMessage()
    }

    // MARK: - Game Control

    /// ゲームを開始
    func startGame() {
        guard gameState.canStartGame, isPlaneDetected else { return }

        // 状態をリセット
        score.reset()
        remainingTime = Constants.gameDuration
        activeTargets.removeAll()

        // ゲームアンカーを設定
        setupGameAnchor()

        // スポーンシステムをリセット
        spawnSystem.reset()
        spawnSystem.parentAnchor = gameAnchor

        // ゲーム開始
        gameState = .playing
        showingGameOver = false

        // タイマー開始
        startTimers()

        updateGuideMessage()
    }

    /// ゲームを一時停止
    func pauseGame() {
        guard gameState == .playing else { return }
        gameState = .paused
        stopTimers()
        showingPauseMenu = true
    }

    /// ゲームを再開
    func resumeGame() {
        guard gameState == .paused else { return }
        gameState = .playing
        showingPauseMenu = false
        startTimers()
    }

    /// ゲームを終了
    func endGame() {
        gameState = .gameOver
        stopTimers()

        // ハイスコア更新
        GameScore.saveHighScore(score.currentScore)
        highScore = GameScore.loadHighScore()

        // すべてのターゲットを削除
        clearAllTargets()

        // ゲームオーバー画面を表示
        showingGameOver = true
    }

    /// ゲームをリスタート
    func restartGame() {
        clearAllTargets()
        startGame()
    }

    // MARK: - Tap Handling

    /// タップ処理
    /// - Parameter location: タップ位置
    func handleTap(at location: CGPoint) {
        guard gameState == .playing, let arView = arView else { return }

        // ヒットテスト
        let results = arView.hitTest(location, query: .nearest, mask: .default)

        for result in results {
            let entity = result.entity

            // TargetComponentを持つエンティティかチェック
            guard var targetComponent = entity.components[TargetComponent.self],
                  !targetComponent.isHit else {
                continue
            }

            // ヒット処理
            targetComponent.isHit = true
            entity.components.set(targetComponent)

            // スコア加算
            let points = targetComponent.points
            score.addHit(points: points)

            // ヒットエフェクト
            if let anchor = gameAnchor {
                let effect = targetRenderer.createHitEffect(
                    at: entity.position,
                    size: targetComponent.size
                )
                anchor.addChild(effect)
            }

            // ヒットアニメーション後に削除
            targetRenderer.performHitAnimation(on: entity) { [weak self] in
                self?.removeTarget(entity: entity, targetId: targetComponent.targetId)
            }

            break // 最初のヒットのみ処理
        }
    }

    // MARK: - Target Management

    private func onTargetSpawned(target: Target, entity: Entity) {
        activeTargets[target.id] = entity
    }

    private func removeTarget(entity: Entity, targetId: UUID) {
        entity.removeFromParent()
        activeTargets.removeValue(forKey: targetId)
        spawnSystem.onTargetRemoved()
    }

    private func clearAllTargets() {
        for (_, entity) in activeTargets {
            entity.removeFromParent()
        }
        activeTargets.removeAll()
        spawnSystem.reset()
    }

    // MARK: - Timer Management

    private func startTimers() {
        // ゲームタイマー（1秒ごと）
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateGameTime()
            }
        }

        // 更新タイマー（フレーム更新、約30fps）
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.frameUpdate()
            }
        }
    }

    private func stopTimers() {
        gameTimer?.invalidate()
        gameTimer = nil
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func updateGameTime() {
        guard gameState == .playing else { return }

        remainingTime -= 1

        if remainingTime <= 0 {
            remainingTime = 0
            endGame()
        }
    }

    private func frameUpdate() {
        guard gameState == .playing else { return }

        let currentTime = Date().timeIntervalSince1970

        // ターゲット出現更新
        spawnSystem.update(currentTime: currentTime, isGameActive: true)

        // 寿命切れターゲットのチェック
        checkExpiredTargets(currentTime: currentTime)
    }

    private func checkExpiredTargets(currentTime: TimeInterval) {
        for (targetId, entity) in activeTargets {
            guard let lifespanComponent = entity.components[LifespanComponent.self],
                  let targetComponent = entity.components[TargetComponent.self],
                  !targetComponent.isHit else {
                continue
            }

            if lifespanComponent.isExpired(currentTime: currentTime) {
                // ミスをカウント
                score.addMiss()

                // フェードアウトアニメーション
                var transform = entity.transform
                transform.scale = .zero

                entity.move(
                    to: transform,
                    relativeTo: entity.parent,
                    duration: 0.3,
                    timingFunction: .easeIn
                )

                // 削除
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.removeTarget(entity: entity, targetId: targetId)
                }
            }
        }
    }

    // MARK: - AR Anchor Setup

    private func setupGameAnchor() {
        guard let arView = arView else { return }

        // 既存のアンカーを削除
        if let existingAnchor = gameAnchor {
            arView.scene.removeAnchor(existingAnchor)
        }

        // 水平面にアンカーを作成
        let anchor = AnchorEntity(
            .plane(.horizontal, classification: .any, minimumBounds: [0.2, 0.2])
        )

        arView.scene.addAnchor(anchor)
        gameAnchor = anchor
        spawnSystem.parentAnchor = anchor
    }

    // MARK: - AR Session State

    func updateARSessionState(_ state: ARCamera.TrackingState) {
        arSessionState = state

        switch state {
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                errorMessage = "デバイスの動きが早すぎます"
            case .insufficientFeatures:
                errorMessage = "周囲の特徴が不十分です"
            case .initializing:
                errorMessage = "ARを初期化中..."
            default:
                errorMessage = "AR追跡が制限されています"
            }
        case .notAvailable:
            errorMessage = "AR機能が利用できません"
        case .normal:
            clearError()
        }
    }

    func onPlaneDetected() {
        isPlaneDetected = true

        if gameState == .waitingForPlane {
            gameState = .ready
        }

        updateGuideMessage()
    }

    // MARK: - Guide Messages

    private func updateGuideMessage() {
        switch gameState {
        case .idle:
            guideMessage = "準備中..."
        case .waitingForPlane:
            guideMessage = "床や机などの平面にカメラを向けてください"
        case .ready:
            guideMessage = "準備完了！「START」をタップしてゲーム開始"
        case .playing:
            guideMessage = nil
        case .paused:
            guideMessage = "一時停止中"
        case .gameOver:
            guideMessage = nil
        }
    }

    // MARK: - Onboarding

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "AsaARGame_HasCompletedOnboarding")
        showingOnboarding = false
        setupAR()
    }

    // MARK: - Error Handling

    func clearError() {
        errorMessage = nil
    }
}

// MARK: - GameScore Statistics Access
extension ARGameViewModel {
    /// ゲーム結果の統計情報を取得
    var gameStatistics: GameScore.Statistics {
        score.generateStatistics()
    }
}
