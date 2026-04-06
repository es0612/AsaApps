import Foundation
import SwiftData
#if os(iOS)
import UIKit
#endif

// MARK: - SampleDataService

/// サンプルデータサービス - デモ動画撮影用のフォトストーリーを生成
/// 5つの多様なテンプレート/テーマで日本人家族向けの実用的なサンプルを投入
@MainActor
public final class SampleDataService {
    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initializer

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// サンプルストーリーを一括投入
    public func loadSampleData() throws {
        let stories = createSampleStories()
        for story in stories {
            modelContext.insert(story)
        }
        try modelContext.save()
    }

    // MARK: - Story Creation

    /// サンプルストーリー5件を生成
    private func createSampleStories() -> [PhotoStory] {
        let now = Date()
        let calendar = Calendar.current

        return [
            createTravelStory(createdAt: calendar.date(byAdding: .day, value: -3, to: now) ?? now),
            createBirthdayStory(createdAt: calendar.date(byAdding: .day, value: -7, to: now) ?? now),
            createSeasonStory(createdAt: calendar.date(byAdding: .day, value: -14, to: now) ?? now),
            createMilestoneStory(createdAt: calendar.date(byAdding: .day, value: -30, to: now) ?? now),
            createDailyLifeStory(createdAt: calendar.date(byAdding: .day, value: -45, to: now) ?? now),
        ]
    }

    /// 旅行ストーリー: 沖縄家族旅行
    private func createTravelStory(createdAt: Date) -> PhotoStory {
        let story = PhotoStory(
            title: "沖縄家族旅行 2026",
            storyDescription: "夏休みに家族で沖縄へ。エメラルドグリーンの海と美味しい食事を満喫しました",
            template: .travel,
            theme: .warm,
            createdAt: createdAt,
            updatedAt: createdAt,
            isFavorite: true
        )
        story.tags = ["旅行", "沖縄", "家族", "夏休み"]

        let pageContents: [(layout: PageLayout, title: String, body: String, emoji: String, gradient: GradientPreset)] = [
            (.singlePhoto, "出発の朝", "わくわく空港集合！", "✈️", .skyBlue),
            (.twoHorizontal, "美ら海水族館", "ジンベエザメに大興奮", "🐠", .ocean),
            (.threeGrid, "ビーチでまったり", "白い砂浜と青い海", "🏖️", .tropical),
            (.photoWithText, "沖縄料理", "ゴーヤチャンプルー最高！", "🍜", .sunset),
            (.singlePhoto, "最高の思い出", "また来年も来たいね", "❤️", .warmGlow),
        ]

        for (index, content) in pageContents.enumerated() {
            let page = createPage(
                order: index,
                layout: content.layout,
                title: content.title,
                body: content.body,
                emoji: content.emoji,
                gradient: content.gradient
            )
            page.story = story
            story.pages.append(page)
        }

        return story
    }

    /// 誕生日ストーリー: お誕生日会
    private func createBirthdayStory(createdAt: Date) -> PhotoStory {
        let story = PhotoStory(
            title: "太郎の5歳のお誕生日",
            storyDescription: "ついに5歳！家族みんなでお祝いしました",
            template: .birthday,
            theme: .pastel,
            createdAt: createdAt,
            updatedAt: createdAt,
            isFavorite: true
        )
        story.tags = ["誕生日", "5歳", "ケーキ", "お祝い"]

        let pageContents: [(layout: PageLayout, title: String, body: String, emoji: String, gradient: GradientPreset)] = [
            (.singlePhoto, "5歳になりました", "おめでとう、太郎！", "🎂", .pinkCandy),
            (.twoHorizontal, "プレゼントタイム", "新しい絵本と恐竜のおもちゃ", "🎁", .pastelDream),
            (.threeGrid, "ケーキを切ったよ", "イチゴのショートケーキ", "🍰", .sweetMint),
            (.photoWithText, "みんなで写真", "また来年もお祝いしようね", "📸", .pinkCandy),
        ]

        for (index, content) in pageContents.enumerated() {
            let page = createPage(
                order: index,
                layout: content.layout,
                title: content.title,
                body: content.body,
                emoji: content.emoji,
                gradient: content.gradient
            )
            page.story = story
            story.pages.append(page)
        }

        return story
    }

    /// 季節ストーリー: 春のピクニック
    private func createSeasonStory(createdAt: Date) -> PhotoStory {
        let story = PhotoStory(
            title: "春のピクニック",
            storyDescription: "桜が満開の公園で家族でピクニック",
            template: .season,
            theme: .natural,
            createdAt: createdAt,
            updatedAt: createdAt,
            isFavorite: false
        )
        story.tags = ["春", "桜", "ピクニック", "公園"]

        let pageContents: [(layout: PageLayout, title: String, body: String, emoji: String, gradient: GradientPreset)] = [
            (.singlePhoto, "満開の桜", "今年も綺麗に咲いた", "🌸", .springPink),
            (.twoVertical, "お弁当タイム", "おにぎりとから揚げ", "🍱", .freshGreen),
            (.fourGrid, "子供たちの笑顔", "公園を駆け回る", "🌳", .meadow),
            (.singlePhoto, "夕日と桜", "今日もいい一日でした", "🌅", .sunset),
        ]

        for (index, content) in pageContents.enumerated() {
            let page = createPage(
                order: index,
                layout: content.layout,
                title: content.title,
                body: content.body,
                emoji: content.emoji,
                gradient: content.gradient
            )
            page.story = story
            story.pages.append(page)
        }

        return story
    }

    /// 記念日ストーリー: 結婚記念日
    private func createMilestoneStory(createdAt: Date) -> PhotoStory {
        let story = PhotoStory(
            title: "結婚10周年記念",
            storyDescription: "10年間ありがとう。これからもよろしく",
            template: .milestone,
            theme: .classic,
            createdAt: createdAt,
            updatedAt: createdAt,
            isFavorite: true
        )
        story.tags = ["結婚記念日", "10周年", "感謝"]

        let pageContents: [(layout: PageLayout, title: String, body: String, emoji: String, gradient: GradientPreset)] = [
            (.singlePhoto, "10年前のあの日", "若かったね", "💍", .classicGold),
            (.photoWithText, "今日の私たち", "10年経っても変わらない笑顔", "💑", .warmGlow),
            (.singlePhoto, "これからも", "20年、30年と続けていこう", "✨", .twilight),
        ]

        for (index, content) in pageContents.enumerated() {
            let page = createPage(
                order: index,
                layout: content.layout,
                title: content.title,
                body: content.body,
                emoji: content.emoji,
                gradient: content.gradient
            )
            page.story = story
            story.pages.append(page)
        }

        return story
    }

    /// 日常ストーリー: 日々の小さな幸せ
    private func createDailyLifeStory(createdAt: Date) -> PhotoStory {
        let story = PhotoStory(
            title: "日々の小さな幸せ",
            storyDescription: "なんでもない日常も、大切な思い出",
            template: .dailyLife,
            theme: .cool,
            createdAt: createdAt,
            updatedAt: createdAt,
            isFavorite: false
        )
        story.tags = ["日常", "家族", "ほっこり"]

        let pageContents: [(layout: PageLayout, title: String, body: String, emoji: String, gradient: GradientPreset)] = [
            (.singlePhoto, "朝のコーヒー", "今日も一日頑張ろう", "☕", .morningSky),
            (.twoHorizontal, "公園で遊ぶ", "子供たちの笑い声", "🌈", .freshGreen),
            (.singlePhoto, "夕食の風景", "みんな揃って いただきます", "🍽️", .warmGlow),
        ]

        for (index, content) in pageContents.enumerated() {
            let page = createPage(
                order: index,
                layout: content.layout,
                title: content.title,
                body: content.body,
                emoji: content.emoji,
                gradient: content.gradient
            )
            page.story = story
            story.pages.append(page)
        }

        return story
    }

    // MARK: - Page Creation

    /// ページを生成（テキスト要素+写真要素+スタンプ要素を含む）
    private func createPage(
        order: Int,
        layout: PageLayout,
        title: String,
        body: String,
        emoji: String,
        gradient: GradientPreset
    ) -> StoryPage {
        let page = StoryPage(
            order: order,
            layout: layout,
            backgroundColorHex: gradient.backgroundHex,
            transition: .fade,
            duration: 3.0
        )

        // 写真要素（グラデーション画像）
        if let imageData = makeGradientImage(emoji: emoji, gradient: gradient) {
            let photo = StoryElement.photoElement(
                imageData: imageData,
                caption: body,
                zOrder: 0
            )
            photo.positionX = 0.5
            photo.positionY = 0.4
            photo.width = 0.85
            photo.height = 0.55
            photo.page = page
            page.elements.append(photo)
        }

        // タイトルテキスト要素
        let titleElement = StoryElement.textElement(
            text: title,
            fontSize: 28,
            colorHex: "#2F3E46",
            zOrder: 1
        )
        titleElement.positionX = 0.5
        titleElement.positionY = 0.78
        titleElement.width = 0.85
        titleElement.height = 0.1
        titleElement.page = page
        page.elements.append(titleElement)

        // 本文テキスト要素
        let bodyElement = StoryElement.textElement(
            text: body,
            fontSize: 16,
            colorHex: "#7A918D",
            zOrder: 2
        )
        bodyElement.positionX = 0.5
        bodyElement.positionY = 0.88
        bodyElement.width = 0.85
        bodyElement.height = 0.08
        bodyElement.page = page
        page.elements.append(bodyElement)

        // スタンプ要素（装飾）
        let sticker = StoryElement.stickerElement(
            name: "heart.fill",
            zOrder: 3
        )
        sticker.positionX = 0.92
        sticker.positionY = 0.08
        sticker.page = page
        page.elements.append(sticker)

        return page
    }

    // MARK: - Image Generation

    /// グラデーションと絵文字でダミー画像を生成
    private func makeGradientImage(emoji: String, gradient: GradientPreset) -> Data? {
        #if os(iOS)
        let size = CGSize(width: 800, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let cgContext = context.cgContext

            // グラデーション描画
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let cgColors = gradient.uiColors.map { $0.cgColor } as CFArray
            if let cgGradient = CGGradient(
                colorsSpace: colorSpace,
                colors: cgColors,
                locations: [0.0, 1.0]
            ) {
                cgContext.drawLinearGradient(
                    cgGradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }

            // 絵文字を中央に大きく描画
            let emojiSize: CGFloat = 240
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: emojiSize),
            ]
            let attrString = NSAttributedString(string: emoji, attributes: attributes)
            let textSize = attrString.size()
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            attrString.draw(in: textRect)
        }

        return image.pngData()
        #else
        return nil
        #endif
    }
}

// MARK: - GradientPreset

/// グラデーションプリセット - サンプル画像生成用
private enum GradientPreset {
    case skyBlue
    case ocean
    case tropical
    case sunset
    case warmGlow
    case pinkCandy
    case pastelDream
    case sweetMint
    case springPink
    case freshGreen
    case meadow
    case classicGold
    case twilight
    case morningSky

    #if os(iOS)
    var uiColors: [UIColor] {
        switch self {
        case .skyBlue:
            return [UIColor(red: 0.53, green: 0.81, blue: 0.98, alpha: 1.0),
                    UIColor(red: 0.27, green: 0.51, blue: 0.71, alpha: 1.0)]
        case .ocean:
            return [UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1.0),
                    UIColor(red: 0.05, green: 0.27, blue: 0.55, alpha: 1.0)]
        case .tropical:
            return [UIColor(red: 0.40, green: 0.85, blue: 0.85, alpha: 1.0),
                    UIColor(red: 0.95, green: 0.85, blue: 0.50, alpha: 1.0)]
        case .sunset:
            return [UIColor(red: 0.99, green: 0.65, blue: 0.35, alpha: 1.0),
                    UIColor(red: 0.93, green: 0.30, blue: 0.40, alpha: 1.0)]
        case .warmGlow:
            return [UIColor(red: 1.00, green: 0.85, blue: 0.55, alpha: 1.0),
                    UIColor(red: 0.85, green: 0.45, blue: 0.30, alpha: 1.0)]
        case .pinkCandy:
            return [UIColor(red: 1.00, green: 0.75, blue: 0.85, alpha: 1.0),
                    UIColor(red: 0.95, green: 0.45, blue: 0.65, alpha: 1.0)]
        case .pastelDream:
            return [UIColor(red: 0.85, green: 0.80, blue: 1.00, alpha: 1.0),
                    UIColor(red: 1.00, green: 0.80, blue: 0.90, alpha: 1.0)]
        case .sweetMint:
            return [UIColor(red: 0.75, green: 0.95, blue: 0.85, alpha: 1.0),
                    UIColor(red: 0.95, green: 0.85, blue: 0.95, alpha: 1.0)]
        case .springPink:
            return [UIColor(red: 1.00, green: 0.80, blue: 0.85, alpha: 1.0),
                    UIColor(red: 0.95, green: 0.65, blue: 0.75, alpha: 1.0)]
        case .freshGreen:
            return [UIColor(red: 0.65, green: 0.90, blue: 0.65, alpha: 1.0),
                    UIColor(red: 0.30, green: 0.60, blue: 0.40, alpha: 1.0)]
        case .meadow:
            return [UIColor(red: 0.80, green: 0.95, blue: 0.55, alpha: 1.0),
                    UIColor(red: 0.40, green: 0.75, blue: 0.35, alpha: 1.0)]
        case .classicGold:
            return [UIColor(red: 0.95, green: 0.85, blue: 0.55, alpha: 1.0),
                    UIColor(red: 0.65, green: 0.50, blue: 0.20, alpha: 1.0)]
        case .twilight:
            return [UIColor(red: 0.55, green: 0.45, blue: 0.75, alpha: 1.0),
                    UIColor(red: 0.25, green: 0.20, blue: 0.45, alpha: 1.0)]
        case .morningSky:
            return [UIColor(red: 0.95, green: 0.85, blue: 0.75, alpha: 1.0),
                    UIColor(red: 0.65, green: 0.85, blue: 0.95, alpha: 1.0)]
        }
    }
    #endif

    var backgroundHex: String {
        switch self {
        case .skyBlue: return "#87CEEB"
        case .ocean: return "#1976D2"
        case .tropical: return "#5DD3D3"
        case .sunset: return "#FF9966"
        case .warmGlow: return "#FFD080"
        case .pinkCandy: return "#FFC0D0"
        case .pastelDream: return "#D9CCFF"
        case .sweetMint: return "#BFF2D9"
        case .springPink: return "#FFCCD5"
        case .freshGreen: return "#A6E6A6"
        case .meadow: return "#CCF28C"
        case .classicGold: return "#F2D98C"
        case .twilight: return "#8C73BF"
        case .morningSky: return "#F2D9BF"
        }
    }
}
