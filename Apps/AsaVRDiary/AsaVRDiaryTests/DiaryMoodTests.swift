//
//  DiaryMoodTests.swift
//  AsaVRDiaryTests
//
//  DiaryMoodのテスト
//

import Testing
import SwiftUI
@testable import AsaVRDiary

@Suite("DiaryMood Tests")
struct DiaryMoodTests {

    // MARK: - Display Name Tests

    @Test("displayNameテスト - すべての気分")
    func testDisplayNames() {
        #expect(DiaryMood.veryHappy.displayName == "とても嬉しい")
        #expect(DiaryMood.happy.displayName == "嬉しい")
        #expect(DiaryMood.neutral.displayName == "普通")
        #expect(DiaryMood.sad.displayName == "悲しい")
        #expect(DiaryMood.verySad.displayName == "とても悲しい")
        #expect(DiaryMood.excited.displayName == "ワクワク")
        #expect(DiaryMood.calm.displayName == "穏やか")
        #expect(DiaryMood.anxious.displayName == "不安")
        #expect(DiaryMood.grateful.displayName == "感謝")
        #expect(DiaryMood.tired.displayName == "疲れた")
    }

    // MARK: - Emoji Tests

    @Test("emojiテスト - すべての気分")
    func testEmojis() {
        #expect(DiaryMood.veryHappy.emoji == "😄")
        #expect(DiaryMood.happy.emoji == "😊")
        #expect(DiaryMood.neutral.emoji == "😐")
        #expect(DiaryMood.sad.emoji == "😢")
        #expect(DiaryMood.verySad.emoji == "😭")
        #expect(DiaryMood.excited.emoji == "🤩")
        #expect(DiaryMood.calm.emoji == "😌")
        #expect(DiaryMood.anxious.emoji == "😰")
        #expect(DiaryMood.grateful.emoji == "🙏")
        #expect(DiaryMood.tired.emoji == "😴")
    }

    // MARK: - VR Y Offset Tests

    @Test("vrYOffsetテスト - ポジティブな気分は上に")
    func testPositiveMoodYOffset() {
        let intensity = 3
        #expect(DiaryMood.veryHappy.vrYOffset(intensity: intensity) > 0)
        #expect(DiaryMood.excited.vrYOffset(intensity: intensity) > 0)
        #expect(DiaryMood.grateful.vrYOffset(intensity: intensity) > 0)
    }

    @Test("vrYOffsetテスト - ネガティブな気分は下に")
    func testNegativeMoodYOffset() {
        let intensity = 3
        #expect(DiaryMood.sad.vrYOffset(intensity: intensity) < 0)
        #expect(DiaryMood.verySad.vrYOffset(intensity: intensity) < 0)
        #expect(DiaryMood.anxious.vrYOffset(intensity: intensity) < 0)
        #expect(DiaryMood.tired.vrYOffset(intensity: intensity) < 0)
    }

    @Test("vrYOffsetテスト - ニュートラルはゼロ")
    func testNeutralMoodYOffset() {
        let intensity = 3
        #expect(DiaryMood.neutral.vrYOffset(intensity: intensity) == 0)
    }

    @Test("vrYOffsetテスト - 強度に応じてスケール")
    func testIntensityScaling() {
        let mood = DiaryMood.veryHappy
        let offset1 = mood.vrYOffset(intensity: 1)
        let offset3 = mood.vrYOffset(intensity: 3)
        let offset5 = mood.vrYOffset(intensity: 5)

        #expect(offset1 < offset3)
        #expect(offset3 < offset5)
    }

    // MARK: - VR Effect Tests

    @Test("vrEffectテスト - veryHappyはparticles")
    func testVeryHappyEffect() {
        let effect = DiaryMood.veryHappy.vrEffect
        if case .particles(let intensity) = effect {
            #expect(intensity == 1.0)
        } else {
            Issue.record("Expected particles effect")
        }
    }

    @Test("vrEffectテスト - happyはglow")
    func testHappyEffect() {
        let effect = DiaryMood.happy.vrEffect
        if case .glow(let intensity) = effect {
            #expect(intensity == 0.8)
        } else {
            Issue.record("Expected glow effect")
        }
    }

    @Test("vrEffectテスト - neutralはnone")
    func testNeutralEffect() {
        let effect = DiaryMood.neutral.vrEffect
        #expect(effect == .none)
    }

    @Test("vrEffectテスト - excitedはpulse")
    func testExcitedEffect() {
        let effect = DiaryMood.excited.vrEffect
        if case .pulse(let intensity) = effect {
            #expect(intensity == 1.0)
        } else {
            Issue.record("Expected pulse effect")
        }
    }

    @Test("vrEffectテスト - sadはshimmer")
    func testSadEffect() {
        let effect = DiaryMood.sad.vrEffect
        if case .shimmer(let intensity) = effect {
            #expect(intensity == 0.3)
        } else {
            Issue.record("Expected shimmer effect")
        }
    }

    // MARK: - All Cases Tests

    @Test("allCasesテスト - 10種類の気分")
    func testAllCasesCount() {
        #expect(DiaryMood.allCases.count == 10)
    }

    // MARK: - Raw Value Tests

    @Test("rawValueからの初期化テスト")
    func testRawValueInitialization() {
        #expect(DiaryMood(rawValue: "veryHappy") == .veryHappy)
        #expect(DiaryMood(rawValue: "neutral") == .neutral)
        #expect(DiaryMood(rawValue: "invalid") == nil)
    }

    // MARK: - Codable Tests

    @Test("Codableテスト")
    func testCodable() throws {
        let original = DiaryMood.grateful
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(DiaryMood.self, from: data)

        #expect(decoded == original)
    }
}

// MARK: - VREffect Tests

@Suite("VREffect Tests")
struct VREffectTests {

    @Test("intensityテスト - none")
    func testNoneIntensity() {
        let effect = VREffect.none
        #expect(effect.intensity == 0)
    }

    @Test("intensityテスト - glow")
    func testGlowIntensity() {
        let effect = VREffect.glow(intensity: 0.7)
        #expect(effect.intensity == 0.7)
    }

    @Test("emissiveIntensityテスト")
    func testEmissiveIntensity() {
        #expect(VREffect.none.emissiveIntensity == 0)
        #expect(VREffect.glow(intensity: 1.0).emissiveIntensity == 0.5)
        #expect(VREffect.pulse(intensity: 1.0).emissiveIntensity == 0.6)
    }

    @Test("roughnessテスト")
    func testRoughness() {
        #expect(VREffect.none.roughness == 0.5)
        #expect(VREffect.shimmer(intensity: 1.0).roughness == 0.1)
        #expect(VREffect.glow(intensity: 1.0).roughness == 0.2)
    }

    @Test("Equatableテスト")
    func testEquatable() {
        #expect(VREffect.none == VREffect.none)
        #expect(VREffect.glow(intensity: 0.5) == VREffect.glow(intensity: 0.5))
        #expect(VREffect.glow(intensity: 0.5) != VREffect.glow(intensity: 0.6))
        #expect(VREffect.glow(intensity: 0.5) != VREffect.pulse(intensity: 0.5))
    }
}
