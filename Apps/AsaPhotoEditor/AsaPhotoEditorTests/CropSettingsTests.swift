import Testing
import Foundation
import CoreGraphics
@testable import AsaPhotoEditor

// MARK: - CropSettings Tests
@Suite("CropSettings Tests")
struct CropSettingsTests {
    // MARK: - Default Values

    @Test("デフォルト値の確認")
    func testDefaultValues() {
        let settings = CropSettings()

        #expect(settings.cropRect == CGRect(x: 0, y: 0, width: 1, height: 1))
        #expect(settings.rotationAngle == 0)
        #expect(settings.isFlippedHorizontally == false)
        #expect(settings.isFlippedVertically == false)
        #expect(settings.aspectRatio == nil)
        #expect(settings.isDefault == true)
    }

    // MARK: - Rotation

    @Test("時計回り回転")
    func testRotateClockwise() {
        var settings = CropSettings()

        settings.rotateClockwise()
        #expect(settings.rotationAngle == 90)

        settings.rotateClockwise()
        #expect(settings.rotationAngle == 180)

        settings.rotateClockwise()
        #expect(settings.rotationAngle == 270)

        settings.rotateClockwise()
        #expect(settings.rotationAngle == 0)
    }

    @Test("反時計回り回転")
    func testRotateCounterClockwise() {
        var settings = CropSettings()

        settings.rotateCounterClockwise()
        #expect(settings.rotationAngle == 270)

        settings.rotateCounterClockwise()
        #expect(settings.rotationAngle == 180)
    }

    @Test("回転回数の計算")
    func testRotationCount() {
        var settings = CropSettings()

        #expect(settings.rotationCount == 0)

        settings.rotationAngle = 90
        #expect(settings.rotationCount == 1)

        settings.rotationAngle = 180
        #expect(settings.rotationCount == 2)

        settings.rotationAngle = 270
        #expect(settings.rotationCount == 3)
    }

    // MARK: - Flip

    @Test("水平反転のトグル")
    func testToggleHorizontalFlip() {
        var settings = CropSettings()

        settings.toggleHorizontalFlip()
        #expect(settings.isFlippedHorizontally == true)

        settings.toggleHorizontalFlip()
        #expect(settings.isFlippedHorizontally == false)
    }

    @Test("垂直反転のトグル")
    func testToggleVerticalFlip() {
        var settings = CropSettings()

        settings.toggleVerticalFlip()
        #expect(settings.isFlippedVertically == true)

        settings.toggleVerticalFlip()
        #expect(settings.isFlippedVertically == false)
    }

    // MARK: - Reset

    @Test("リセットでデフォルト値に戻る")
    func testReset() {
        var settings = CropSettings()
        settings.rotationAngle = 90
        settings.isFlippedHorizontally = true
        settings.aspectRatio = .square

        settings.reset()

        #expect(settings.isDefault == true)
        #expect(settings.rotationAngle == 0)
        #expect(settings.isFlippedHorizontally == false)
        #expect(settings.aspectRatio == nil)
    }

    // MARK: - isDefault

    @Test("変更後はisDefaultがfalse")
    func testIsDefaultFalse() {
        var settings = CropSettings()

        settings.rotationAngle = 90
        #expect(settings.isDefault == false)
    }

    // MARK: - Codable

    @Test("Codableのテスト")
    func testCodable() throws {
        var original = CropSettings()
        original.rotationAngle = 180
        original.isFlippedHorizontally = true
        original.aspectRatio = .ratio16x9

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CropSettings.self, from: data)

        #expect(decoded.rotationAngle == original.rotationAngle)
        #expect(decoded.isFlippedHorizontally == original.isFlippedHorizontally)
        #expect(decoded.aspectRatio == original.aspectRatio)
    }
}

// MARK: - AspectRatio Tests
@Suite("AspectRatio Tests")
struct AspectRatioTests {
    @Test("自由比率のratioはnil")
    func testFreeRatioIsNil() {
        #expect(AspectRatio.free.ratio == nil)
    }

    @Test("正方形のratioは1.0")
    func testSquareRatio() {
        #expect(AspectRatio.square.ratio == 1.0)
    }

    @Test("4:3の比率")
    func testRatio4x3() {
        let ratio = AspectRatio.ratio4x3.ratio
        #expect(ratio != nil)
        #expect(ratio! == 4.0 / 3.0)
    }

    @Test("16:9の比率")
    func testRatio16x9() {
        let ratio = AspectRatio.ratio16x9.ratio
        #expect(ratio != nil)
        #expect(ratio! == 16.0 / 9.0)
    }

    @Test("すべてのケースにアイコン名がある")
    func testIconNames() {
        for ratio in AspectRatio.allCases {
            #expect(!ratio.iconName.isEmpty)
        }
    }

    @Test("すべてのケースに説明がある")
    func testDescriptions() {
        for ratio in AspectRatio.allCases {
            #expect(!ratio.description.isEmpty)
        }
    }
}
