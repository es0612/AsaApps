import Testing
import Foundation
@testable import AsaPhotoEditor

// MARK: - FilterPreset Tests
@Suite("FilterPreset Tests")
struct FilterPresetTests {
    // MARK: - Basic Properties

    @Test("すべてのプリセットにフィルター名がある（none以外）")
    func testCIFilterNames() {
        for preset in FilterPreset.allCases {
            if preset == .none {
                #expect(preset.ciFilterName == nil)
            } else {
                #expect(preset.ciFilterName != nil)
            }
        }
    }

    @Test("すべてのプリセットにアイコン名がある")
    func testIconNames() {
        for preset in FilterPreset.allCases {
            #expect(!preset.iconName.isEmpty)
        }
    }

    @Test("すべてのプリセットに説明がある")
    func testDescriptions() {
        for preset in FilterPreset.allCases {
            #expect(!preset.description.isEmpty)
        }
    }

    // MARK: - Intensity Support

    @Test("強度調整対応プリセット")
    func testSupportsIntensity() {
        #expect(FilterPreset.sepia.supportsIntensity == true)
        #expect(FilterPreset.blur.supportsIntensity == true)
        #expect(FilterPreset.pixellate.supportsIntensity == true)
        #expect(FilterPreset.vivid.supportsIntensity == true)

        #expect(FilterPreset.noir.supportsIntensity == false)
        #expect(FilterPreset.vintage.supportsIntensity == false)
    }

    @Test("デフォルト強度の値")
    func testDefaultIntensity() {
        #expect(FilterPreset.sepia.defaultIntensity == 0.8)
        #expect(FilterPreset.blur.defaultIntensity == 10.0)
        #expect(FilterPreset.pixellate.defaultIntensity == 10.0)
    }

    // MARK: - Intensity Range

    @Test("セピアの強度範囲")
    func testSepiaIntensityRange() {
        let range = FilterPreset.sepia.intensityRange
        #expect(range.lowerBound == 0.0)
        #expect(range.upperBound == 1.0)
    }

    @Test("ぼかしの強度範囲")
    func testBlurIntensityRange() {
        let range = FilterPreset.blur.intensityRange
        #expect(range.lowerBound == 0.0)
        #expect(range.upperBound == 50.0)
    }

    // MARK: - Codable

    @Test("エンコード・デコードが正しく動作する")
    func testCodable() throws {
        let original = FilterPreset.sepia

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FilterPreset.self, from: data)

        #expect(decoded == original)
    }
}

// MARK: - FilterSettings Tests
@Suite("FilterSettings Tests")
struct FilterSettingsTests {
    @Test("デフォルト設定")
    func testDefaultSettings() {
        let settings = FilterSettings()
        #expect(settings.preset == .none)
        #expect(settings.intensity == 1.0)
        #expect(settings.isDefault == true)
    }

    @Test("プリセット変更後はisDefaultがfalse")
    func testIsDefaultFalse() {
        var settings = FilterSettings()
        settings.preset = .sepia
        #expect(settings.isDefault == false)
    }

    @Test("Codableのテスト")
    func testCodable() throws {
        var original = FilterSettings()
        original.preset = .vintage
        original.intensity = 0.8

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FilterSettings.self, from: data)

        #expect(decoded.preset == original.preset)
        #expect(decoded.intensity == original.intensity)
    }
}
