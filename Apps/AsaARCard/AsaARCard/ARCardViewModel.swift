import Foundation
import ARKit
import RealityKit

// MARK: - ARCardViewModel
@Observable
final class ARCardViewModel {
    
    // MARK: - Properties
    var businessCard: BusinessCard = BusinessCard.loadFromUserDefaults()
    var isARViewReady = false
    var isCardVisible = false
    var showingSettings = false
    var showingCardFlip = false
    var errorMessage: String?
    var arSessionState: ARCamera.TrackingState = .notAvailable
    
    // AR関連のプロパティ
    var arView: ARView?
    var cardEntity: ModelEntity?
    
    // MARK: - Initialization
    init() {
        setupAR()
    }
    
    // MARK: - AR Setup
    private func setupAR() {
        // AR利用可能性をチェック
        guard ARWorldTrackingConfiguration.isSupported else {
            errorMessage = "このデバイスはAR機能をサポートしていません"
            return
        }
        
        // ARViewの準備完了を設定
        isARViewReady = true
    }
    
    // MARK: - Public Methods
    
    /// AR名刺を表示
    func showBusinessCard() {
        guard isARViewReady else { return }
        createCardEntity()
        isCardVisible = true
    }
    
    /// AR名刺を非表示
    func hideBusinessCard() {
        cardEntity?.removeFromParent()
        cardEntity = nil
        isCardVisible = false
    }
    
    /// 名刺の表裏を切り替え
    func flipCard() {
        guard let entity = cardEntity else { return }
        
        showingCardFlip.toggle()
        
        // ARCardRendererの高品質アニメーションを使用
        entity.flipCard(duration: 0.8)
    }
    
    /// 設定画面を表示
    func showSettings() {
        showingSettings = true
    }
    
    /// 名刺データを更新
    func updateBusinessCard(_ newCard: BusinessCard) {
        businessCard = newCard
        businessCard.saveToUserDefaults()
        
        // AR名刺が表示中の場合は更新
        if isCardVisible {
            updateCardEntity()
        }
    }
    
    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    /// 3D名刺エンティティを作成
    private func createCardEntity() {
        guard let arView = arView else { return }
        
        // 既存のエンティティがある場合は削除
        cardEntity?.removeFromParent()
        
        // ARCardRendererで高品質な3D名刺を作成
        let entity = ARCardRenderer.createBusinessCardEntity(businessCard: businessCard)
        
        // アンカーを作成（ユーザーの前方適切な距離）
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: [0.1, 0.1]))
        
        // 名刺の位置と向きを調整
        entity.position = [0, 0.02, 0] // 平面から少し浮かせる
        entity.orientation = simd_quatf(angle: 0, axis: [0, 1, 0]) // 水平配置
        
        anchor.addChild(entity)
        
        // シーンに追加
        arView.scene.addAnchor(anchor)
        
        self.cardEntity = entity
    }
    
    /// 名刺エンティティを更新
    private func updateCardEntity() {
        // 既存のエンティティがある場合は再作成
        if isCardVisible {
            createCardEntity()
        }
    }
    
    
    /// ARセッションの状態を更新
    func updateARSessionState(_ state: ARCamera.TrackingState) {
        arSessionState = state
        
        switch state {
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                errorMessage = "デバイスの動きが早すぎます。ゆっくりと動かしてください。"
            case .insufficientFeatures:
                errorMessage = "周囲の特徴が不十分です。明るい場所で試してください。"
            case .initializing:
                errorMessage = "ARセッションを初期化しています..."
            default:
                errorMessage = "AR追跡が制限されています。"
            }
        case .notAvailable:
            errorMessage = "AR機能が利用できません。"
        case .normal:
            clearError()
        }
    }
}