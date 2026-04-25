//
//  DiaryEntityRenderer.swift
//  AsaVRDiary
//
//  日記エントリーを3Dエンティティとしてレンダリング
//

import Foundation
import RealityKit
import UIKit

// MARK: - DiaryEntityRenderer

/// 日記を3Dカードエンティティとしてレンダリング
enum DiaryEntityRenderer {

    // MARK: - Constants

    private enum CardDimensions {
        static let width: Float = 0.15        // 15cm
        static let height: Float = 0.10       // 10cm
        static let thickness: Float = 0.002   // 2mm
    }

    private enum TextureSize {
        static let width: CGFloat = 750       // 解像度
        static let height: CGFloat = 500
    }

    // MARK: - Public Methods

    /// 日記エントリーから3Dエンティティを作成
    static func createDiaryEntity(for entry: DiaryEntry) -> ModelEntity {
        let mesh = createCardMesh()
        let frontTexture = createFrontTexture(for: entry)
        let backTexture = createBackTexture(for: entry)
        let frontMaterial = createMaterial(texture: frontTexture, mood: entry.mood)
        let backMaterial = createMaterial(texture: backTexture, mood: entry.mood)

        let entity = ModelEntity(mesh: mesh, materials: [frontMaterial, backMaterial])
        entity.name = "DiaryEntry_\(entry.id.uuidString)"

        // 衝突検出を追加（タップジェスチャー用）
        entity.generateCollisionShapes(recursive: false)

        // フリップコンポーネントを追加
        entity.components.set(DiaryCardComponent(entryId: entry.id))

        return entity
    }

    /// タイムラインでの位置を計算
    static func calculateTimelinePosition(
        for entry: DiaryEntry,
        referenceDate: Date,
        index: Int
    ) -> SIMD3<Float> {
        let calendar = Calendar.current

        // X軸: 日付（1日 = 0.2m間隔）
        let daysDifference = calendar.dateComponents([.day], from: referenceDate, to: entry.date).day ?? 0
        let x = Float(daysDifference) * 0.2

        // Y軸: 感情強度（強いほど高い位置）+ 気分オフセット
        let baseY: Float = 0.0
        let moodOffset = entry.mood.vrYOffset(intensity: entry.moodIntensity)
        let y = baseY + moodOffset

        // Z軸: カテゴリ（奥行きで分類）
        let z = entry.category.vrZOffset

        return SIMD3<Float>(x, y, z)
    }

    /// グリッド配置での位置を計算
    static func calculateGridPosition(index: Int, columns: Int = 4) -> SIMD3<Float> {
        let row = index / columns
        let col = index % columns

        let spacing: Float = 0.18  // カード間隔
        let x = Float(col - columns / 2) * spacing
        let y = Float(-row) * spacing * 0.7  // 行間は少し狭く
        let z: Float = -0.5  // カメラから0.5m前方

        return SIMD3<Float>(x, y, z)
    }

    // MARK: - Private Methods

    /// カードメッシュを作成
    private static func createCardMesh() -> MeshResource {
        MeshResource.generateBox(
            width: CardDimensions.width,
            height: CardDimensions.height,
            depth: CardDimensions.thickness
        )
    }

    /// 表面テクスチャを作成
    private static func createFrontTexture(for entry: DiaryEntry) -> CGImage? {
        let size = CGSize(width: TextureSize.width, height: TextureSize.height)

        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // 背景色（気分に応じた色）
        let bgColor = entry.mood.uiColor.withAlphaComponent(0.15)
        context.setFillColor(bgColor.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        // 白い内側背景
        let inset: CGFloat = 15
        context.setFillColor(UIColor.white.withAlphaComponent(0.95).cgColor)
        context.fill(CGRect(x: inset, y: inset, width: size.width - inset * 2, height: size.height - inset * 2))

        // 境界線（気分の色）
        context.setStrokeColor(entry.mood.uiColor.cgColor)
        context.setLineWidth(4)
        context.stroke(CGRect(x: inset, y: inset, width: size.width - inset * 2, height: size.height - inset * 2))

        // テキストカラー
        let textColor = UIColor(red: 0.18, green: 0.24, blue: 0.27, alpha: 1.0)

        // 日付を描画
        drawText(
            entry.formattedDate,
            at: CGPoint(x: size.width * 0.06, y: size.height * 0.08),
            font: UIFont.systemFont(ofSize: 28, weight: .medium),
            color: UIColor.gray,
            maxWidth: size.width * 0.5
        )

        // 感情絵文字を描画
        drawText(
            entry.mood.emoji,
            at: CGPoint(x: size.width * 0.85, y: size.height * 0.08),
            font: UIFont.systemFont(ofSize: 40),
            color: textColor,
            maxWidth: 50
        )

        // カテゴリアイコンを描画（SF Symbols風のテキスト）
        let categoryIcon = categoryIconText(for: entry.category)
        drawText(
            categoryIcon,
            at: CGPoint(x: size.width * 0.06, y: size.height * 0.22),
            font: UIFont.systemFont(ofSize: 24),
            color: UIColor(entry.category.color),
            maxWidth: 30
        )

        // タイトルを描画
        drawText(
            entry.title,
            at: CGPoint(x: size.width * 0.12, y: size.height * 0.22),
            font: UIFont.boldSystemFont(ofSize: 36),
            color: textColor,
            maxWidth: size.width * 0.8
        )

        // 本文プレビューを描画
        drawText(
            entry.contentPreview,
            at: CGPoint(x: size.width * 0.06, y: size.height * 0.42),
            font: UIFont.systemFont(ofSize: 24),
            color: textColor.withAlphaComponent(0.8),
            maxWidth: size.width * 0.88
        )

        // お気に入りマーク
        if entry.isFavorite {
            drawText(
                "★",
                at: CGPoint(x: size.width * 0.92, y: size.height * 0.85),
                font: UIFont.systemFont(ofSize: 32),
                color: UIColor.systemYellow,
                maxWidth: 40
            )
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image?.cgImage
    }

    /// 裏面テクスチャを作成
    private static func createBackTexture(for entry: DiaryEntry) -> CGImage? {
        let size = CGSize(width: TextureSize.width, height: TextureSize.height)

        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // 背景色（気分に応じた色）
        context.setFillColor(entry.mood.uiColor.withAlphaComponent(0.8).cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        // 装飾パターン
        context.setFillColor(UIColor.white.withAlphaComponent(0.1).cgColor)
        for i in 0..<15 {
            let x = CGFloat(i) * size.width / 15
            context.fill(CGRect(x: x, y: 0, width: 2, height: size.height))
        }

        // カテゴリと気分を表示
        let displayText = "\(entry.category.displayName) | \(entry.mood.displayName)"
        drawText(
            displayText,
            at: CGPoint(x: size.width * 0.5, y: size.height * 0.45),
            font: UIFont.boldSystemFont(ofSize: 32),
            color: UIColor.white,
            maxWidth: size.width * 0.8,
            alignment: .center
        )

        // 大きな絵文字
        drawText(
            entry.mood.emoji,
            at: CGPoint(x: size.width * 0.5, y: size.height * 0.6),
            font: UIFont.systemFont(ofSize: 80),
            color: UIColor.white,
            maxWidth: 100,
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
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byTruncatingTail

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]

        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()

        var drawPoint = point
        if alignment == .center {
            drawPoint.x -= min(textSize.width, maxWidth) / 2
        }

        let rect = CGRect(
            origin: drawPoint,
            size: CGSize(width: min(textSize.width, maxWidth), height: textSize.height * 2)
        )
        attributedString.draw(in: rect)
    }

    /// カテゴリのアイコンテキスト
    private static func categoryIconText(for category: DiaryCategory) -> String {
        switch category {
        case .daily: return "☀"
        case .work: return "💼"
        case .family: return "🏠"
        case .hobby: return "🎨"
        case .travel: return "✈"
        case .health: return "❤"
        case .learning: return "📚"
        case .special: return "⭐"
        case .other: return "○"
        }
    }

    /// マテリアルを作成（UnlitMaterial: ライト不要で常に同じ見た目になる）
    private static func createMaterial(texture: CGImage?, mood: DiaryMood) -> Material {
        var material = UnlitMaterial()

        if let texture = texture,
           let textureResource = try? TextureResource.generate(
               from: texture,
               options: .init(semantic: .color)
           ) {
            material.color = .init(tint: .white, texture: .init(textureResource))
        } else {
            // フォールバック: 気分の色をベースに
            material.color = .init(tint: mood.uiColor.withAlphaComponent(0.95))
        }

        return material
    }
}

// MARK: - DiaryCardComponent

/// 日記カードの状態管理コンポーネント
struct DiaryCardComponent: Component {
    var entryId: UUID
    var isFlipped: Bool = false
    var isSelected: Bool = false
}

// MARK: - ModelEntity Extension

extension ModelEntity {
    /// 日記カードを回転させる
    func flipDiaryCard(duration: TimeInterval = 0.6) {
        let currentTransform = self.transform
        let rotation = simd_quatf(angle: Float.pi, axis: [0, 1, 0])
        let newTransform = Transform(
            scale: currentTransform.scale,
            rotation: currentTransform.rotation * rotation,
            translation: currentTransform.translation
        )

        self.move(
            to: newTransform,
            relativeTo: self.parent,
            duration: duration,
            timingFunction: .easeInOut
        )

        if var cardComponent = self.components[DiaryCardComponent.self] {
            cardComponent.isFlipped.toggle()
            self.components[DiaryCardComponent.self] = cardComponent
        }
    }

    /// 日記カードを選択状態にする
    func selectDiaryCard(selected: Bool, duration: TimeInterval = 0.3) {
        let scale: Float = selected ? 1.2 : 1.0
        let currentTransform = self.transform
        let newTransform = Transform(
            scale: SIMD3<Float>(repeating: scale),
            rotation: currentTransform.rotation,
            translation: currentTransform.translation
        )

        self.move(
            to: newTransform,
            relativeTo: self.parent,
            duration: duration,
            timingFunction: .easeInOut
        )

        if var cardComponent = self.components[DiaryCardComponent.self] {
            cardComponent.isSelected = selected
            self.components[DiaryCardComponent.self] = cardComponent
        }
    }
}
