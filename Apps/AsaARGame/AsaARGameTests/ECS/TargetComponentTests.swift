import Testing
import simd
@testable import AsaARGame

// MARK: - TargetComponentTests
@Suite("TargetComponent Tests")
struct TargetComponentTests {

    @Test("TargetComponentの初期化が正しい")
    func testInitialization() {
        let targetId = UUID()
        let component = TargetComponent(targetId: targetId, size: .medium)

        #expect(component.targetId == targetId)
        #expect(component.size == .medium)
        #expect(component.points == 25)
        #expect(!component.isHit)
    }

    @Test("Targetモデルから初期化")
    func testInitFromTarget() {
        let target = Target(
            size: .small,
            position: SIMD3<Float>(1, 2, 3)
        )

        let component = TargetComponent(from: target)

        #expect(component.targetId == target.id)
        #expect(component.size == .small)
        #expect(component.points == 50)
        #expect(!component.isHit)
    }

    @Test("ヒット状態を変更可能")
    func testIsHitMutation() {
        var component = TargetComponent(targetId: UUID(), size: .large)

        #expect(!component.isHit)

        component.isHit = true

        #expect(component.isHit)
    }

    @Test("各サイズで正しい得点が設定される")
    func testPointsForEachSize() {
        let largeComponent = TargetComponent(targetId: UUID(), size: .large)
        let mediumComponent = TargetComponent(targetId: UUID(), size: .medium)
        let smallComponent = TargetComponent(targetId: UUID(), size: .small)

        #expect(largeComponent.points == 10)
        #expect(mediumComponent.points == 25)
        #expect(smallComponent.points == 50)
    }
}
