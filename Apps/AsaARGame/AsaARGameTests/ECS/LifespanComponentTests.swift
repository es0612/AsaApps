import Testing
import simd
@testable import AsaARGame

// MARK: - LifespanComponentTests
@Suite("LifespanComponent Tests")
struct LifespanComponentTests {

    @Test("LifespanComponentの初期化が正しい")
    func testInitialization() {
        let createdAt: TimeInterval = 1000.0
        let lifespan: TimeInterval = 3.0

        let component = LifespanComponent(createdAt: createdAt, lifespan: lifespan)

        #expect(component.createdAt == createdAt)
        #expect(component.lifespan == lifespan)
        #expect(!component.isDisappearing)
    }

    @Test("Targetモデルから初期化")
    func testInitFromTarget() {
        let target = Target(
            size: .medium,
            position: SIMD3<Float>(0, 0, 0),
            createdAt: 2000.0,
            lifespan: 5.0
        )

        let component = LifespanComponent(from: target)

        #expect(component.createdAt == 2000.0)
        #expect(component.lifespan == 5.0)
    }

    @Test("期限切れ判定が正しい")
    func testIsExpired() {
        let component = LifespanComponent(createdAt: 1000.0, lifespan: 3.0)

        #expect(!component.isExpired(currentTime: 1000.0))
        #expect(!component.isExpired(currentTime: 1002.9))
        #expect(component.isExpired(currentTime: 1003.0))
        #expect(component.isExpired(currentTime: 1005.0))
    }

    @Test("残り寿命の割合が正しく計算される")
    func testRemainingLifeRatio() {
        let component = LifespanComponent(createdAt: 1000.0, lifespan: 4.0)

        #expect(component.remainingLifeRatio(currentTime: 1000.0) == 1.0)
        #expect(component.remainingLifeRatio(currentTime: 1002.0) == 0.5)
        #expect(component.remainingLifeRatio(currentTime: 1004.0) == 0.0)
        #expect(component.remainingLifeRatio(currentTime: 1006.0) == 0.0)
    }

    @Test("残り時間が正しく計算される")
    func testRemainingTime() {
        let component = LifespanComponent(createdAt: 1000.0, lifespan: 5.0)

        #expect(component.remainingTime(currentTime: 1000.0) == 5.0)
        #expect(component.remainingTime(currentTime: 1003.0) == 2.0)
        #expect(component.remainingTime(currentTime: 1005.0) == 0.0)
        #expect(component.remainingTime(currentTime: 1010.0) == 0.0)
    }

    @Test("消滅フラグを変更可能")
    func testIsDisappearingMutation() {
        var component = LifespanComponent(createdAt: 1000.0, lifespan: 3.0)

        #expect(!component.isDisappearing)

        component.isDisappearing = true

        #expect(component.isDisappearing)
    }
}
