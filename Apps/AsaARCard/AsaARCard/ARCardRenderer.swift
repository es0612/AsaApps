import Foundation
import RealityKit
import ARKit
import UIKit

// MARK: - ARCardRenderer
class ARCardRenderer {
    
    // MARK: - Constants
    private struct CardDimensions {
        static let width: Float = 0.085  // 85mm (標準名刺幅)
        static let height: Float = 0.055 // 55mm (標準名刺高)
        static let thickness: Float = 0.001 // 1mm厚
        static let cornerRadius: Float = 0.003 // 3mm角丸
    }
    
    // MARK: - Public Methods
    
    /// 3D名刺エンティティを作成
    static func createBusinessCardEntity(businessCard: BusinessCard) -> ModelEntity {
        // 名刺のメッシュを作成
        let mesh = createCardMesh()
        
        // 表面のテクスチャを作成
        let frontTexture = createFrontTexture(businessCard: businessCard)
        let backTexture = createBackTexture()
        
        // マテリアルを作成
        let frontMaterial = createCardMaterial(texture: frontTexture)
        let backMaterial = createCardMaterial(texture: backTexture)
        
        // エンティティを作成
        let entity = ModelEntity(mesh: mesh, materials: [frontMaterial, backMaterial])
        
        // 名刺のプロパティを設定
        entity.name = "BusinessCard"
        entity.position = [0, 0, 0]
        
        // ジェスチャを追加
        addGestureRecognizers(to: entity)
        
        return entity
    }
    
    // MARK: - Private Methods
    
    /// 名刺メッシュを作成
    private static func createCardMesh() -> MeshResource {
        // 角丸四角形のメッシュを生成
        return MeshResource.generateBox(
            width: CardDimensions.width,
            height: CardDimensions.height,
            depth: CardDimensions.thickness
        )
    }
    
    /// 名刺の表面テクスチャを作成
    private static func createFrontTexture(businessCard: BusinessCard) -> CGImage? {
        let size = CGSize(width: 850, height: 550) // 10倍解像度
        
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 背景色を設定（AsaCoffeeColorの代替）
        context.setFillColor(UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0).cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // 名刺の境界線
        context.setStrokeColor(UIColor(red: 0.78, green: 0.55, blue: 0.33, alpha: 1.0).cgColor)
        context.setLineWidth(4)
        context.stroke(CGRect(x: 10, y: 10, width: size.width - 20, height: size.height - 20))
        
        // テキスト描画の準備
        let textColor = UIColor(red: 0.18, green: 0.25, blue: 0.27, alpha: 1.0) // AsaDarkSlate
        
        // 名前を描画（大きく）
        if !businessCard.name.isEmpty {
            drawText(
                businessCard.name,
                at: CGPoint(x: size.width * 0.05, y: size.height * 0.2),
                font: UIFont.boldSystemFont(ofSize: 60),
                color: textColor,
                maxWidth: size.width * 0.9
            )
        }
        
        // 役職を描画
        if !businessCard.title.isEmpty {
            drawText(
                businessCard.title,
                at: CGPoint(x: size.width * 0.05, y: size.height * 0.35),
                font: UIFont.systemFont(ofSize: 36),
                color: textColor,
                maxWidth: size.width * 0.9
            )
        }
        
        // 会社名を描画
        if !businessCard.company.isEmpty {
            drawText(
                businessCard.company,
                at: CGPoint(x: size.width * 0.05, y: size.height * 0.5),
                font: UIFont.systemFont(ofSize: 40),
                color: textColor,
                maxWidth: size.width * 0.9
            )
        }
        
        // 連絡先を描画（小さく）
        var contactY: CGFloat = size.height * 0.7
        let contactSpacing: CGFloat = 30
        
        if !businessCard.email.isEmpty {
            drawText(
                "📧 \(businessCard.email)",
                at: CGPoint(x: size.width * 0.05, y: contactY),
                font: UIFont.systemFont(ofSize: 24),
                color: textColor,
                maxWidth: size.width * 0.9
            )
            contactY += contactSpacing
        }
        
        if !businessCard.phone.isEmpty {
            drawText(
                "📱 \(businessCard.phone)",
                at: CGPoint(x: size.width * 0.05, y: contactY),
                font: UIFont.systemFont(ofSize: 24),
                color: textColor,
                maxWidth: size.width * 0.9
            )
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image?.cgImage
    }
    
    /// 名刺の裏面テクスチャを作成
    private static func createBackTexture() -> CGImage? {
        let size = CGSize(width: 850, height: 550)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 背景色
        context.setFillColor(UIColor(red: 0.48, green: 0.57, blue: 0.55, alpha: 1.0).cgColor) // AsaMutedSage
        context.fill(CGRect(origin: .zero, size: size))
        
        // ロゴやパターンを描画（シンプルなパターン）
        context.setFillColor(UIColor(red: 0.78, green: 0.55, blue: 0.33, alpha: 0.3).cgColor)
        for i in 0..<10 {
            let x = CGFloat(i) * size.width / 10
            context.fill(CGRect(x: x, y: 0, width: 2, height: size.height))
        }
        
        // AsaApps ロゴ的なテキスト
        drawText(
            "AsaApps",
            at: CGPoint(x: size.width * 0.5, y: size.height * 0.5),
            font: UIFont.boldSystemFont(ofSize: 80),
            color: UIColor.white,
            maxWidth: size.width * 0.8,
            alignment: .center
        )
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image?.cgImage
    }
    
    /// テキストを描画
    private static func drawText(
        _ text: String,
        at point: CGPoint,
        font: UIFont,
        color: UIColor,
        maxWidth: CGFloat,
        alignment: NSTextAlignment = .left
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        
        var drawPoint = point
        if alignment == .center {
            drawPoint.x -= textSize.width / 2
        }
        
        let rect = CGRect(origin: drawPoint, size: CGSize(width: min(textSize.width, maxWidth), height: textSize.height))
        attributedString.draw(in: rect)
    }
    
    /// マテリアルを作成
    private static func createCardMaterial(texture: CGImage?) -> Material {
        var material = SimpleMaterial()
        
        if let texture = texture {
            let textureResource = try? TextureResource.generate(from: texture, options: .init(semantic: .color))
            material.color = .init(texture: .init(textureResource))
        } else {
            material.color = .init(tint: .white, texture: nil)
        }
        
        // 名刺らしい質感
        material.roughness = 0.3
        material.metallic = 0.0
        
        return material
    }
    
    /// ジェスチャ認識を追加
    private static func addGestureRecognizers(to entity: ModelEntity) {
        // タップジェスチャ
        entity.generateCollisionShapes(recursive: false)
        
        // エンティティにインタラクション可能マークを設定
        entity.components.set(InputTargetComponent())
        
        // カスタムコンポーネントで回転状態を管理
        entity.components.set(CardFlipComponent())
    }
}

// MARK: - カスタムコンポーネント
struct CardFlipComponent: Component {
    var isFlipped: Bool = false
    var flipAnimation: AnimationResource?
}

// MARK: - Extension - ModelEntity
extension ModelEntity {
    
    /// 名刺を回転させる
    func flipCard(duration: TimeInterval = 0.8) {
        // Y軸中心に180度回転
        let currentTransform = self.transform
        let rotation = simd_quatf(angle: Float.pi, axis: [0, 1, 0])
        let newTransform = Transform(
            scale: currentTransform.scale,
            rotation: currentTransform.rotation * rotation,
            translation: currentTransform.translation
        )
        
        // アニメーションで回転
        self.move(
            to: newTransform,
            relativeTo: self.parent,
            duration: duration,
            timingFunction: .easeInOut
        )
        
        // フリップ状態を更新
        if var flipComponent = self.components[CardFlipComponent.self] {
            flipComponent.isFlipped.toggle()
            self.components[CardFlipComponent.self] = flipComponent
        }
    }
}