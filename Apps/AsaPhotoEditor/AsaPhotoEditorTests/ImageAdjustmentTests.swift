import Testing
import Foundation
@testable import AsaPhotoEditor

// MARK: - ImageAdjustment Tests
@Suite("ImageAdjustment Tests")
struct ImageAdjustmentTests {
    // MARK: - Default Values

    @Test("デフォルト値の確認")
    func testDefaultValues() {
        let adjustment = ImageAdjustment()

        #expect(adjustment.brightness == 0.0)
        #expect(adjustment.contrast == 1.0)
        #expect(adjustment.saturation == 1.0)
        #expect(adjustment.exposure == 0.0)
        #expect(adjustment.sharpness == 0.0)
        #expect(adjustment.highlights == 0.0)
        #expect(adjustment.shadows == 0.0)
    }

    @Test("isDefaultがtrueになる")
    func testIsDefaultTrue() {
        let adjustment = ImageAdjustment()
        #expect(adjustment.isDefault == true)
    }

    @Test("変更後はisDefaultがfalseになる")
    func testIsDefaultFalseAfterChange() {
        var adjustment = ImageAdjustment()
        adjustment.brightness = 0.5
        #expect(adjustment.isDefault == false)
    }

    // MARK: - Range Validation

    @Test("明るさの範囲")
    func testBrightnessRange() {
        let range = ImageAdjustment.brightnessRange
        #expect(range.lowerBound == -1.0)
        #expect(range.upperBound == 1.0)
    }

    @Test("コントラストの範囲")
    func testContrastRange() {
        let range = ImageAdjustment.contrastRange
        #expect(range.lowerBound == 0.5)
        #expect(range.upperBound == 2.0)
    }

    @Test("彩度の範囲")
    func testSaturationRange() {
        let range = ImageAdjustment.saturationRange
        #expect(range.lowerBound == 0.0)
        #expect(range.upperBound == 2.0)
    }

    // MARK: - Equatable

    @Test("同じ値は等しい")
    func testEquality() {
        let adjustment1 = ImageAdjustment()
        let adjustment2 = ImageAdjustment()
        #expect(adjustment1 == adjustment2)
    }

    @Test("異なる値は等しくない")
    func testInequality() {
        var adjustment1 = ImageAdjustment()
        var adjustment2 = ImageAdjustment()
        adjustment2.brightness = 0.5
        #expect(adjustment1 != adjustment2)
    }

    // MARK: - Codable

    @Test("エンコード・デコードが正しく動作する")
    func testCodable() throws {
        var original = ImageAdjustment()
        original.brightness = 0.3
        original.contrast = 1.5
        original.saturation = 0.8

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ImageAdjustment.self, from: data)

        #expect(decoded.brightness == original.brightness)
        #expect(decoded.contrast == original.contrast)
        #expect(decoded.saturation == original.saturation)
    }
}

// MARK: - AdjustmentType Tests
@Suite("AdjustmentType Tests")
struct AdjustmentTypeTests {
    @Test("すべてのケースにアイコン名がある")
    func testIconNames() {
        for type in AdjustmentType.allCases {
            #expect(!type.iconName.isEmpty)
        }
    }

    @Test("getValue が正しい値を返す")
    func testGetValue() {
        var adjustment = ImageAdjustment()
        adjustment.brightness = 0.5

        let value = AdjustmentType.brightness.getValue(from: adjustment)
        #expect(value == 0.5)
    }

    @Test("setValue が正しく設定する")
    func testSetValue() {
        var adjustment = ImageAdjustment()
        AdjustmentType.brightness.setValue(0.7, to: &adjustment)
        #expect(adjustment.brightness == 0.7)
    }

    @Test("各タイプのデフォルト値")
    func testDefaultValues() {
        #expect(AdjustmentType.brightness.defaultValue == 0.0)
        #expect(AdjustmentType.contrast.defaultValue == 1.0)
        #expect(AdjustmentType.saturation.defaultValue == 1.0)
    }
}
