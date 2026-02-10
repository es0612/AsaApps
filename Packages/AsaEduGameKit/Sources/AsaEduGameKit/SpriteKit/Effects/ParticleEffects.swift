import SpriteKit
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - パーティクルエフェクト集

/// コードベースのパーティクルエフェクト（.sksファイル不使用）
/// 子供向けにカラフルで楽しい見た目のエフェクトを提供
@MainActor
public enum ParticleEffects {

    // MARK: - カラフルな色パレット

    /// パーティクル用カラーパレット
    private static let particleColors: [SKColor] = [
        SKColor(red: 1.00, green: 0.84, blue: 0.00, alpha: 1.0), // 金色
        SKColor(red: 0.95, green: 0.30, blue: 0.30, alpha: 1.0), // 赤
        SKColor(red: 0.30, green: 0.85, blue: 0.40, alpha: 1.0), // 緑
        SKColor(red: 0.20, green: 0.60, blue: 0.95, alpha: 1.0), // 青
        SKColor(red: 0.80, green: 0.40, blue: 0.90, alpha: 1.0), // 紫
        SKColor(red: 1.00, green: 0.60, blue: 0.20, alpha: 1.0), // オレンジ
        SKColor(red: 1.00, green: 0.70, blue: 0.80, alpha: 1.0), // ピンク
    ]

    // MARK: - スターバースト

    /// 星形パーティクルバースト（正解時に使用）
    /// - Parameter position: エフェクト表示位置
    /// - Returns: 設定済みのSKEmitterNode
    public static func starBurst(at position: CGPoint) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        emitter.position = position

        // パーティクル生成設定
        emitter.particleBirthRate = 40
        emitter.numParticlesToEmit = 30
        emitter.particleLifetime = 1.0
        emitter.particleLifetimeRange = 0.3

        // サイズ
        emitter.particleSize = CGSize(width: 12, height: 12)
        emitter.particleScaleRange = 0.5
        emitter.particleScaleSpeed = -0.3

        // 速度
        emitter.particleSpeed = 150
        emitter.particleSpeedRange = 50
        emitter.emissionAngleRange = CGFloat.pi * 2 // 全方向

        // 色（金色ベース）
        emitter.particleColor = particleColors[0]
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorBlendFactorRange = 0.3
        emitter.particleColorSequence = nil

        // アルファ
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.8

        // 回転
        emitter.particleRotation = 0
        emitter.particleRotationRange = CGFloat.pi * 2
        emitter.particleRotationSpeed = 2.0

        // 重力
        emitter.yAcceleration = -100

        emitter.zPosition = 100

        return emitter
    }

    // MARK: - 花火

    /// 花火エフェクト（コンボ達成時に使用）
    /// - Parameter position: エフェクト表示位置
    /// - Returns: 設定済みのSKEmitterNode
    public static func fireworks(at position: CGPoint) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        emitter.position = position

        // パーティクル生成設定
        emitter.particleBirthRate = 80
        emitter.numParticlesToEmit = 60
        emitter.particleLifetime = 1.5
        emitter.particleLifetimeRange = 0.5

        // サイズ
        emitter.particleSize = CGSize(width: 8, height: 8)
        emitter.particleScaleRange = 0.6
        emitter.particleScaleSpeed = -0.2

        // 速度
        emitter.particleSpeed = 200
        emitter.particleSpeedRange = 80
        emitter.emissionAngleRange = CGFloat.pi * 2

        // カラフルな色
        emitter.particleColor = particleColors.randomElement() ?? particleColors[0]
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorBlendFactorRange = 0.5

        // 色の変化シーケンス
        let colorKeyframeSequence = SKKeyframeSequence(
            keyframeValues: [
                particleColors[0],
                particleColors[3],
                particleColors[4],
            ],
            times: [0, 0.5, 1.0]
        )
        colorKeyframeSequence.interpolationMode = .linear
        emitter.particleColorSequence = colorKeyframeSequence

        // アルファ
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.5

        // 重力
        emitter.yAcceleration = -150

        emitter.zPosition = 100

        return emitter
    }

    // MARK: - 紙吹雪

    /// 紙吹雪エフェクト（パーフェクト時に使用）
    /// - Parameter frame: エフェクト表示範囲
    /// - Returns: 設定済みのSKEmitterNode
    public static func confetti(in frame: CGRect) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // 画面上部全体から降らせる
        emitter.position = CGPoint(x: frame.midX, y: frame.maxY + 20)
        emitter.particlePositionRange = CGVector(dx: frame.width, dy: 0)

        // パーティクル生成設定
        emitter.particleBirthRate = 30
        emitter.numParticlesToEmit = 80
        emitter.particleLifetime = 3.0
        emitter.particleLifetimeRange = 1.0

        // サイズ（小さな四角形）
        emitter.particleSize = CGSize(width: 10, height: 6)
        emitter.particleScaleRange = 0.5

        // 速度（下方向に緩やかに落下）
        emitter.particleSpeed = 80
        emitter.particleSpeedRange = 40
        emitter.emissionAngle = -CGFloat.pi / 2 // 下方向
        emitter.emissionAngleRange = CGFloat.pi / 4

        // カラフルな色
        emitter.particleColor = particleColors[0]
        emitter.particleColorBlendFactor = 1.0

        let colorSequence = SKKeyframeSequence(
            keyframeValues: [
                particleColors[0],
                particleColors[1],
                particleColors[2],
                particleColors[3],
                particleColors[4],
                particleColors[5],
            ],
            times: [0, 0.2, 0.4, 0.6, 0.8, 1.0]
        )
        colorSequence.interpolationMode = .linear
        emitter.particleColorSequence = colorSequence

        // アルファ
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.2

        // 回転（紙吹雪がくるくる回る）
        emitter.particleRotation = 0
        emitter.particleRotationRange = CGFloat.pi * 2
        emitter.particleRotationSpeed = 3.0

        // 横揺れ
        emitter.xAcceleration = 20

        // 重力
        emitter.yAcceleration = -50

        emitter.zPosition = 100

        return emitter
    }

    // MARK: - キラキラ

    /// キラキラエフェクト（キャラクターのお祝い時に使用）
    /// - Parameter position: エフェクト表示位置
    /// - Returns: 設定済みのSKEmitterNode
    public static func sparkle(at position: CGPoint) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        emitter.position = position
        emitter.particlePositionRange = CGVector(dx: 60, dy: 60)

        // パーティクル生成設定
        emitter.particleBirthRate = 15
        emitter.numParticlesToEmit = 20
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.3

        // サイズ（小さめのキラキラ）
        emitter.particleSize = CGSize(width: 6, height: 6)
        emitter.particleScaleRange = 0.4
        emitter.particleScaleSpeed = -0.5

        // ほぼ静止（ふわっと浮く）
        emitter.particleSpeed = 30
        emitter.particleSpeedRange = 20
        emitter.emissionAngleRange = CGFloat.pi * 2

        // 金色のキラキラ
        emitter.particleColor = SKColor(red: 1.0, green: 0.90, blue: 0.40, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorBlendFactorRange = 0.3
        emitter.particleColorSequence = nil

        // アルファ（点滅）
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.0

        // 軽い上昇
        emitter.yAcceleration = 20

        emitter.zPosition = 100

        return emitter
    }
}
