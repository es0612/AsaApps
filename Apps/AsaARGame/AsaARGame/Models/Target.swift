import Foundation
import simd

// MARK: - TargetSize
/// ターゲットのサイズ種別
enum TargetSize: String, CaseIterable, Sendable, Codable {
    case large   // 大（0.08m）
    case medium  // 中（0.05m）
    case small   // 小（0.03m）

    // MARK: - Properties

    /// 半径（メートル）
    var radius: Float {
        switch self {
        case .large:  return 0.08
        case .medium: return 0.05
        case .small:  return 0.03
        }
    }

    /// 基本得点
    var basePoints: Int {
        switch self {
        case .large:  return 10
        case .medium: return 25
        case .small:  return 50
        }
    }

    /// 出現確率（合計が1.0になるように）
    var spawnWeight: Double {
        switch self {
        case .large:  return 0.5  // 50%
        case .medium: return 0.35 // 35%
        case .small:  return 0.15 // 15%
        }
    }

    /// ランダムにサイズを選択（重み付き）
    static func random() -> TargetSize {
        let random = Double.random(in: 0..<1)
        var cumulative = 0.0

        for size in allCases {
            cumulative += size.spawnWeight
            if random < cumulative {
                return size
            }
        }
        return .large
    }
}

// MARK: - Target
/// ターゲットのデータモデル（Sendable準拠）
struct Target: Identifiable, Sendable, Equatable {
    // MARK: - Properties

    let id: UUID
    let size: TargetSize
    let position: SIMD3<Float>
    let createdAt: TimeInterval
    let lifespan: TimeInterval

    // MARK: - Computed Properties

    /// 基本得点
    var points: Int {
        size.basePoints
    }

    /// 期限切れかどうかを判定
    func isExpired(currentTime: TimeInterval) -> Bool {
        currentTime - createdAt >= lifespan
    }

    /// 残り寿命の割合（0.0〜1.0）
    func remainingLifeRatio(currentTime: TimeInterval) -> Double {
        let elapsed = currentTime - createdAt
        let remaining = max(0, lifespan - elapsed)
        return remaining / lifespan
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        size: TargetSize = .random(),
        position: SIMD3<Float>,
        createdAt: TimeInterval = Date().timeIntervalSince1970,
        lifespan: TimeInterval = 3.0
    ) {
        self.id = id
        self.size = size
        self.position = position
        self.createdAt = createdAt
        self.lifespan = lifespan
    }
}

// MARK: - Target Factory
extension Target {
    /// ランダムな位置にターゲットを生成
    /// - Parameters:
    ///   - centerX: 中心X座標
    ///   - centerZ: 中心Z座標
    ///   - radius: 出現範囲の半径（メートル）
    ///   - minY: 最小Y座標（高さ）
    ///   - maxY: 最大Y座標（高さ）
    /// - Returns: 新しいターゲット
    static func createRandom(
        centerX: Float = 0,
        centerZ: Float = -1.0,
        radius: Float = 0.5,
        minY: Float = 0.1,
        maxY: Float = 0.5
    ) -> Target {
        // 円形の範囲内でランダムな位置を生成
        let angle = Float.random(in: 0..<(2 * .pi))
        let distance = Float.random(in: 0..<radius)
        let x = centerX + cos(angle) * distance
        let z = centerZ + sin(angle) * distance
        let y = Float.random(in: minY...maxY)

        return Target(
            size: .random(),
            position: SIMD3<Float>(x, y, z)
        )
    }
}
