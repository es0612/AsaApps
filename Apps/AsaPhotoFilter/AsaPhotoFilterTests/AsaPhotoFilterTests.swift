import Testing
@testable import AsaPhotoFilter

struct AsaPhotoFilterTests {

    @Test("フィルタータイプの表示名が正しく設定されている")
    func testFilterTypeDisplayNames() async throws {
        #expect(FilterType.none.displayName == "フィルターなし")
        #expect(FilterType.sepia.displayName == "セピア")
        #expect(FilterType.noir.displayName == "ノワール")
        #expect(FilterType.vintage.displayName == "ビンテージ")
        #expect(FilterType.vivid.displayName == "鮮やか")
        #expect(FilterType.dramatic.displayName == "ドラマチック")
        #expect(FilterType.mono.displayName == "モノクロ")
        #expect(FilterType.tonal.displayName == "トーン調整")
    }
    
    @Test("セピアフィルターは強度調整をサポートする")
    func testSepiaSupportsIntensity() async throws {
        #expect(FilterType.sepia.supportsIntensity == true)
        #expect(FilterType.noir.supportsIntensity == false)
        #expect(FilterType.none.supportsIntensity == false)
    }
    
    @Test("ImageFilterServiceが初期化される")
    func testImageFilterServiceInitialization() async throws {
        let service = ImageFilterService()
        // ImageFilterServiceが正常に初期化されることを確認
        #expect(service != nil)
    }
    
    @Test("FilterViewModelが初期状態で正しく設定される")
    func testFilterViewModelInitialState() async throws {
        let viewModel = FilterViewModel()
        
        #expect(viewModel.selectedFilter == .none)
        #expect(viewModel.filterIntensity == 1.0)
        #expect(viewModel.originalImage == nil)
        #expect(viewModel.filteredImage == nil)
        #expect(viewModel.isProcessing == false)
    }
}