import Testing
import simd
@testable import AsaARGame

// MARK: - TargetSizeTests
@Suite("TargetSize Tests")
struct TargetSizeTests {

    @Test("各サイズの半径が正しい")
    func testRadius() {
        #expect(TargetSize.large.radius == 0.08)
        #expect(TargetSize.medium.radius == 0.05)
        #expect(TargetSize.small.radius == 0.03)
    }

    @Test("各サイズの基本得点が正しい")
    func testBasePoints() {
        #expect(TargetSize.large.basePoints == 10)
        #expect(TargetSize.medium.basePoints == 25)
        #expect(TargetSize.small.basePoints == 50)
    }

    @Test("出現確率の合計が1.0")
    func testSpawnWeightTotal() {
        let total = TargetSize.allCases.reduce(0) { $0 + $1.spawnWeight }
        #expect(total == 1.0)
    }

    @Test("ランダム選択が有効なサイズを返す")
    func testRandomReturnsValidSize() {
        for _ in 0..<100 {
            let size = TargetSize.random()
            #expect(TargetSize.allCases.contains(size))
        }
    }
}

// MARK: - TargetTests
@Suite("Target Tests")
struct TargetTests {

    @Test("ターゲットの初期化が正しい")
    func testInitialization() {
        let position = SIMD3<Float>(1.0, 2.0, 3.0)
        let target = Target(
            size: .medium,
            position: position,
            createdAt: 1000.0,
            lifespan: 3.0
        )

        #expect(target.size == .medium)
        #expect(target.position == position)
        #expect(target.points == 25)
        #expect(target.createdAt == 1000.0)
        #expect(target.lifespan == 3.0)
    }

    @Test("期限切れ判定が正しい")
    func testIsExpired() {
        let target = Target(
            size: .large,
            position: SIMD3<Float>(0, 0, 0),
            createdAt: 1000.0,
            lifespan: 3.0
        )

        // 生成直後は期限切れではない
        #expect(!target.isExpired(currentTime: 1000.0))

        // 2秒後はまだ期限切れではない
        #expect(!target.isExpired(currentTime: 1002.0))

        // 3秒後は期限切れ
        #expect(target.isExpired(currentTime: 1003.0))

        // 4秒後も期限切れ
        #expect(target.isExpired(currentTime: 1004.0))
    }

    @Test("残り寿命の割合が正しく計算される")
    func testRemainingLifeRatio() {
        let target = Target(
            size: .small,
            position: SIMD3<Float>(0, 0, 0),
            createdAt: 1000.0,
            lifespan: 4.0
        )

        // 生成直後は100%
        #expect(target.remainingLifeRatio(currentTime: 1000.0) == 1.0)

        // 2秒後は50%
        #expect(target.remainingLifeRatio(currentTime: 1002.0) == 0.5)

        // 4秒後は0%
        #expect(target.remainingLifeRatio(currentTime: 1004.0) == 0.0)

        // 5秒後も0%（負にならない）
        #expect(target.remainingLifeRatio(currentTime: 1005.0) == 0.0)
    }

    @Test("ファクトリメソッドでランダムターゲットが生成される")
    func testCreateRandom() {
        let target = Target.createRandom(
            centerX: 0,
            centerZ: -1.0,
            radius: 0.5,
            minY: 0.1,
            maxY: 0.5
        )

        // 位置が範囲内にある
        #expect(abs(target.position.x) <= 0.5)
        #expect(target.position.y >= 0.1)
        #expect(target.position.y <= 0.5)
        #expect(target.position.z >= -1.5)
        #expect(target.position.z <= -0.5)

        // 有効なサイズ
        #expect(TargetSize.allCases.contains(target.size))
    }

    @Test("ターゲットはIdentifiable")
    func testIdentifiable() {
        let target1 = Target(size: .large, position: SIMD3<Float>(0, 0, 0))
        let target2 = Target(size: .large, position: SIMD3<Float>(0, 0, 0))

        // 異なるIDを持つ
        #expect(target1.id != target2.id)
    }

    @Test("ターゲットはEquatable")
    func testEquatable() {
        let id = UUID()
        let position = SIMD3<Float>(1, 2, 3)
        let createdAt = Date().timeIntervalSince1970

        let target1 = Target(
            id: id,
            size: .medium,
            position: position,
            createdAt: createdAt,
            lifespan: 3.0
        )
        let target2 = Target(
            id: id,
            size: .medium,
            position: position,
            createdAt: createdAt,
            lifespan: 3.0
        )

        #expect(target1 == target2)
    }
}
