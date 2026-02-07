import Foundation
import SwiftData
import Testing

@testable import AsaPhotoStoryKit

// MARK: - PhotoStory テスト

@Suite("PhotoStory モデルテスト")
struct PhotoStoryTests {
    @Test("PhotoStory 初期化テスト - デフォルト値の確認")
    func testPhotoStoryDefaultInit() {
        let story = PhotoStory()

        #expect(story.title == "新しいストーリー")
        #expect(story.storyDescription == nil)
        #expect(story.templateRawValue == "blank")
        #expect(story.themeRawValue == "warm")
        #expect(story.isFavorite == false)
        #expect(story.pages.isEmpty)
        #expect(story.thumbnailData == nil)
        #expect(story.tagsJSON == nil)
    }

    @Test("PhotoStory template computed property - rawValueとenum間の変換")
    func testTemplateComputedProperty() {
        let story = PhotoStory(template: .travel)
        #expect(story.template == .travel)
        #expect(story.templateRawValue == "travel")

        story.template = .birthday
        #expect(story.template == .birthday)
        #expect(story.templateRawValue == "birthday")
    }

    @Test("PhotoStory theme computed property - rawValueとenum間の変換")
    func testThemeComputedProperty() {
        let story = PhotoStory(theme: .cool)
        #expect(story.theme == .cool)
        #expect(story.themeRawValue == "cool")

        story.theme = .pastel
        #expect(story.theme == .pastel)
        #expect(story.themeRawValue == "pastel")
    }

    @Test("PhotoStory tags computed property - JSON Data ↔ [String] 変換")
    func testTagsComputedProperty() {
        let story = PhotoStory()

        // 初期値は空配列
        #expect(story.tags.isEmpty)

        // タグを設定
        story.tags = ["旅行", "家族", "夏"]
        #expect(story.tags.count == 3)
        #expect(story.tags.contains("旅行"))
        #expect(story.tags.contains("家族"))
        #expect(story.tags.contains("夏"))

        // tagsJSONにデータが保存されている
        #expect(story.tagsJSON != nil)

        // 空配列を設定
        story.tags = []
        #expect(story.tags.isEmpty)
    }

    @Test("PhotoStory isFavorite トグル")
    func testIsFavoriteToggle() {
        let story = PhotoStory()
        #expect(story.isFavorite == false)

        story.isFavorite = true
        #expect(story.isFavorite == true)

        story.isFavorite.toggle()
        #expect(story.isFavorite == false)
    }

    @Test("PhotoStory pageCount - ページ数の正しい取得")
    func testPageCount() {
        let story = PhotoStory()
        #expect(story.pageCount == 0)

        let page1 = StoryPage(order: 0)
        let page2 = StoryPage(order: 1)
        story.pages.append(page1)
        story.pages.append(page2)
        #expect(story.pageCount == 2)
    }
}

// MARK: - StoryPage テスト

@Suite("StoryPage モデルテスト")
struct StoryPageTests {
    @Test("StoryPage 初期化テスト - デフォルト値の確認")
    func testStoryPageDefaultInit() {
        let page = StoryPage()

        #expect(page.order == 0)
        #expect(page.layoutRawValue == "singlePhoto")
        #expect(page.backgroundColorHex == nil)
        #expect(page.transitionRawValue == "fade")
        #expect(page.duration == 3.0)
        #expect(page.elements.isEmpty)
        #expect(page.backgroundImageData == nil)
    }

    @Test("StoryPage layout computed property - rawValueとenum間の変換")
    func testLayoutComputedProperty() {
        let page = StoryPage(layout: .twoHorizontal)
        #expect(page.layout == .twoHorizontal)
        #expect(page.layoutRawValue == "twoHorizontal")

        page.layout = .fourGrid
        #expect(page.layout == .fourGrid)
        #expect(page.layoutRawValue == "fourGrid")
    }

    @Test("StoryPage transition computed property - rawValueとenum間の変換")
    func testTransitionComputedProperty() {
        let page = StoryPage(transition: .slide)
        #expect(page.transition == .slide)
        #expect(page.transitionRawValue == "slide")

        page.transition = .dissolve
        #expect(page.transition == .dissolve)
        #expect(page.transitionRawValue == "dissolve")
    }

    @Test("StoryPage duration デフォルト値 - 3.0秒")
    func testDurationDefault() {
        let page = StoryPage()
        #expect(page.duration == 3.0)

        let customPage = StoryPage(duration: 5.0)
        #expect(customPage.duration == 5.0)
    }

    @Test("StoryPage order 管理 - ページ順序の設定と取得")
    func testOrderManagement() {
        let page1 = StoryPage(order: 0)
        let page2 = StoryPage(order: 1)
        let page3 = StoryPage(order: 2)

        #expect(page1.order == 0)
        #expect(page2.order == 1)
        #expect(page3.order == 2)

        // order変更
        page2.order = 5
        #expect(page2.order == 5)
    }
}

// MARK: - StoryElement テスト

@Suite("StoryElement モデルテスト")
struct StoryElementTests {
    @Test("StoryElement photo タイプの初期化")
    func testPhotoElementInit() {
        let element = StoryElement(type: .photo)
        #expect(element.elementType == .photo)
        #expect(element.typeRawValue == "photo")
        #expect(element.positionX == 0.5)
        #expect(element.positionY == 0.5)
        #expect(element.opacity == 1.0)
        #expect(element.rotation == 0)
    }

    @Test("StoryElement text タイプの初期化")
    func testTextElementInit() {
        let element = StoryElement(type: .text)
        #expect(element.elementType == .text)
        #expect(element.typeRawValue == "text")
    }

    @Test("StoryElement sticker タイプの初期化")
    func testStickerElementInit() {
        let element = StoryElement(type: .sticker)
        #expect(element.elementType == .sticker)
        #expect(element.typeRawValue == "sticker")
    }

    @Test("StoryElement drawing タイプの初期化")
    func testDrawingElementInit() {
        let element = StoryElement(type: .drawing)
        #expect(element.elementType == .drawing)
        #expect(element.typeRawValue == "drawing")
    }

    @Test("StoryElement elementType computed property - rawValueとenum間の変換")
    func testElementTypeComputedProperty() {
        let element = StoryElement(type: .photo)
        #expect(element.elementType == .photo)

        element.elementType = .text
        #expect(element.elementType == .text)
        #expect(element.typeRawValue == "text")
    }

    @Test("StoryElement 正規化座標の範囲検証 - 0.0〜1.0")
    func testNormalizedCoordinates() {
        let element = StoryElement(
            positionX: 0.3,
            positionY: 0.7,
            width: 0.5,
            height: 0.4
        )

        #expect(element.positionX == 0.3)
        #expect(element.positionY == 0.7)
        #expect(element.position.x == 0.3)
        #expect(element.position.y == 0.7)
        #expect(element.size.width == 0.5)
        #expect(element.size.height == 0.4)
    }

    @Test("StoryElement テキスト要素プロパティ - text, fontName, fontSize, textColorHex")
    func testTextProperties() {
        let element = StoryElement(type: .text)
        element.text = "テストテキスト"
        element.fontName = "HiraginoSans-W6"
        element.fontSize = 32
        element.textColorHex = "#FF0000"

        #expect(element.text == "テストテキスト")
        #expect(element.fontName == "HiraginoSans-W6")
        #expect(element.fontSize == 32)
        #expect(element.textColorHex == "#FF0000")
    }

    @Test("StoryElement ファクトリメソッド - photoElement")
    func testPhotoElementFactory() {
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        let element = StoryElement.photoElement(
            imageData: imageData,
            caption: "テストキャプション",
            zOrder: 3
        )

        #expect(element.elementType == .photo)
        #expect(element.imageData == imageData)
        #expect(element.captionText == "テストキャプション")
        #expect(element.zOrder == 3)
    }

    @Test("StoryElement ファクトリメソッド - textElement")
    func testTextElementFactory() {
        let element = StoryElement.textElement(
            text: "見出し",
            fontName: "HiraginoSans-W7",
            fontSize: 48,
            colorHex: "#000000",
            zOrder: 1
        )

        #expect(element.elementType == .text)
        #expect(element.text == "見出し")
        #expect(element.fontName == "HiraginoSans-W7")
        #expect(element.fontSize == 48)
        #expect(element.textColorHex == "#000000")
        #expect(element.zOrder == 1)
        #expect(element.width == 0.6)
        #expect(element.height == 0.15)
    }

    @Test("StoryElement ファクトリメソッド - stickerElement")
    func testStickerElementFactory() {
        let element = StoryElement.stickerElement(name: "heart.fill", zOrder: 2)

        #expect(element.elementType == .sticker)
        #expect(element.stickerName == "heart.fill")
        #expect(element.zOrder == 2)
        #expect(element.width == 0.15)
        #expect(element.height == 0.15)
    }

    @Test("StoryElement ファクトリメソッド - drawingElement")
    func testDrawingElementFactory() {
        let drawingData = Data([0x01, 0x02, 0x03])
        let element = StoryElement.drawingElement(drawingData: drawingData, zOrder: 5)

        #expect(element.elementType == .drawing)
        #expect(element.drawingData == drawingData)
        #expect(element.zOrder == 5)
    }
}

// MARK: - 補助型テスト

@Suite("補助型テスト")
struct AuxiliaryTypeTests {
    @Test("StoryTemplate 全ケース - displayName, iconName, defaultPageCount")
    func testStoryTemplateAllCases() {
        #expect(StoryTemplate.allCases.count == 7)

        // displayName が空でないことを確認
        for template in StoryTemplate.allCases {
            #expect(!template.displayName.isEmpty)
            #expect(!template.iconName.isEmpty)
            #expect(template.defaultPageCount > 0)
        }

        // 個別値の確認
        #expect(StoryTemplate.blank.displayName == "白紙")
        #expect(StoryTemplate.blank.defaultPageCount == 1)
        #expect(StoryTemplate.travel.displayName == "旅行")
        #expect(StoryTemplate.travel.defaultPageCount == 5)
        #expect(StoryTemplate.birthday.iconName == "birthday.cake")
    }

    @Test("StoryTheme 全ケース - カラーHEX値")
    func testStoryThemeAllCases() {
        #expect(StoryTheme.allCases.count == 6)

        for theme in StoryTheme.allCases {
            // HEXカラーが#で始まることを確認
            #expect(theme.primaryColorHex.hasPrefix("#"))
            #expect(theme.secondaryColorHex.hasPrefix("#"))
            #expect(theme.backgroundColorHex.hasPrefix("#"))
            #expect(!theme.displayName.isEmpty)
        }

        // 個別値の確認
        #expect(StoryTheme.warm.primaryColorHex == "#C68C53")
        #expect(StoryTheme.cool.primaryColorHex == "#4A90D9")
    }

    @Test("PageLayout 全ケース - elementCount, displayName, iconName")
    func testPageLayoutAllCases() {
        #expect(PageLayout.allCases.count == 8)

        for layout in PageLayout.allCases {
            #expect(!layout.displayName.isEmpty)
            #expect(!layout.iconName.isEmpty)
        }

        // elementCount の確認
        #expect(PageLayout.singlePhoto.elementCount == 1)
        #expect(PageLayout.twoHorizontal.elementCount == 2)
        #expect(PageLayout.twoVertical.elementCount == 2)
        #expect(PageLayout.threeGrid.elementCount == 3)
        #expect(PageLayout.fourGrid.elementCount == 4)
        #expect(PageLayout.photoWithText.elementCount == 2)
        #expect(PageLayout.textOnly.elementCount == 1)
        #expect(PageLayout.freeform.elementCount == 0)
    }

    @Test("ElementType rawValue 変換")
    func testElementTypeRawValue() {
        #expect(ElementType.allCases.count == 4)

        #expect(ElementType(rawValue: "photo") == .photo)
        #expect(ElementType(rawValue: "text") == .text)
        #expect(ElementType(rawValue: "sticker") == .sticker)
        #expect(ElementType(rawValue: "drawing") == .drawing)
        #expect(ElementType(rawValue: "invalid") == nil)

        // displayName と iconName
        for type in ElementType.allCases {
            #expect(!type.displayName.isEmpty)
            #expect(!type.iconName.isEmpty)
        }
    }

    @Test("ExportSettings デフォルト値")
    func testExportSettingsDefault() {
        let settings = ExportSettings.default

        #expect(settings.format == .video)
        #expect(settings.resolution == .hd1080p)
        #expect(settings.includeAudio == false)
        #expect(settings.quality == 0.8)

        // ExportFormat
        #expect(ExportFormat.allCases.count == 3)
        #expect(ExportFormat.video.fileExtension == "mp4")
        #expect(ExportFormat.pdf.fileExtension == "pdf")
        #expect(ExportFormat.images.fileExtension == "png")

        // ExportResolution
        #expect(ExportResolution.hd1080p.width == 1920)
        #expect(ExportResolution.hd1080p.height == 1080)
        #expect(ExportResolution.uhd4K.width == 3840)
        #expect(ExportResolution.uhd4K.height == 2160)
    }

    @Test("PageTransition 全ケース - displayName, defaultDuration")
    func testPageTransitionAllCases() {
        #expect(PageTransition.allCases.count == 5)

        for transition in PageTransition.allCases {
            #expect(!transition.displayName.isEmpty)
            #expect(transition.defaultDuration >= 0)
        }

        #expect(PageTransition.none.defaultDuration == 0)
        #expect(PageTransition.fade.defaultDuration == 0.5)
        #expect(PageTransition.slide.defaultDuration == 0.4)
    }
}
