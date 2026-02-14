import Testing
import Foundation

@testable import AsaCommunityKit

@Suite("CommunityPost モデルテスト")
struct CommunityPostTests {

    @Test("初期化テスト - デフォルト値が正しく設定される")
    func testInitialization() {
        let post = CommunityPost(title: "テスト投稿", content: "テスト内容")
        #expect(post.title == "テスト投稿")
        #expect(post.content == "テスト内容")
        #expect(post.category == .general)
        #expect(post.isRead == false)
        #expect(post.isPinned == false)
        #expect(post.likeCount == 0)
        #expect(post.commentCount == 0)
        #expect(post.sentimentScore == nil)
    }

    @Test("category アクセサ - rawValue 経由で正しく変換される")
    func testCategoryAccessor() {
        let post = CommunityPost(title: "イベント投稿", content: "内容", category: .event)
        #expect(post.category == .event)
        #expect(post.categoryRawValue == "イベント")

        post.category = .safety
        #expect(post.category == .safety)
        #expect(post.categoryRawValue == "防犯・防災")
    }

    @Test("category アクセサ - 不正な rawValue はデフォルトを返す")
    func testCategoryAccessorInvalidRawValue() {
        let post = CommunityPost(title: "テスト", content: "")
        post.categoryRawValue = "存在しないカテゴリ"
        #expect(post.category == .general)
    }

    @Test("hasLocation - 位置情報の有無を正しく判定する")
    func testHasLocation() {
        let postWithLocation = CommunityPost(
            title: "場所付き", content: "", latitude: 35.68, longitude: 139.76
        )
        #expect(postWithLocation.hasLocation == true)

        let postWithoutLocation = CommunityPost(title: "場所なし", content: "")
        #expect(postWithoutLocation.hasLocation == false)

        let postPartialLocation = CommunityPost(title: "部分", content: "", latitude: 35.68)
        #expect(postPartialLocation.hasLocation == false)
    }

    @Test("timeAgoText - 「たった今」が返される")
    func testTimeAgoTextJustNow() {
        let post = CommunityPost(title: "今", content: "")
        #expect(post.timeAgoText == "たった今")
    }

    @Test("timeAgoText - 分前が返される")
    func testTimeAgoTextMinutesAgo() {
        let post = CommunityPost(title: "テスト", content: "")
        post.createdAt = Date().addingTimeInterval(-300) // 5分前
        #expect(post.timeAgoText == "5分前")
    }

    @Test("timeAgoText - 時間前が返される")
    func testTimeAgoTextHoursAgo() {
        let post = CommunityPost(title: "テスト", content: "")
        post.createdAt = Date().addingTimeInterval(-7200) // 2時間前
        #expect(post.timeAgoText == "2時間前")
    }

    @Test("timeAgoText - 日前が返される")
    func testTimeAgoTextDaysAgo() {
        let post = CommunityPost(title: "テスト", content: "")
        post.createdAt = Date().addingTimeInterval(-259200) // 3日前
        #expect(post.timeAgoText == "3日前")
    }

    @Test("timeAgoText - 週間前が返される")
    func testTimeAgoTextWeeksAgo() {
        let post = CommunityPost(title: "テスト", content: "")
        post.createdAt = Date().addingTimeInterval(-1209600) // 14日前 = 2週間前
        #expect(post.timeAgoText == "2週間前")
    }
}
