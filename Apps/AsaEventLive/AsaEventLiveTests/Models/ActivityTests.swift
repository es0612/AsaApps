import Testing
import Foundation
@testable import AsaEventLive

// MARK: - Activity Tests

struct ActivityTests {
    // MARK: - Initialization Tests

    @Test("アクティビティ初期化テスト")
    func testActivityInitialization() {
        let activity = Activity(
            eventId: "event-1",
            userId: "user-1",
            userName: "テストユーザー",
            type: .joined
        )

        #expect(activity.eventId == "event-1")
        #expect(activity.userId == "user-1")
        #expect(activity.userName == "テストユーザー")
        #expect(activity.type == .joined)
    }

    // MARK: - Type Tests

    @Test("アクティビティタイプアイコンテスト")
    func testActivityTypeIcons() {
        #expect(ActivityType.joined.icon == "person.badge.plus")
        #expect(ActivityType.left.icon == "person.badge.minus")
        #expect(ActivityType.posted.icon == "text.bubble")
        #expect(ActivityType.liked.icon == "heart.fill")
        #expect(ActivityType.commented.icon == "bubble.left")
        #expect(ActivityType.milestone.icon == "flag.fill")
        #expect(ActivityType.photoAdded.icon == "photo")
        #expect(ActivityType.settingChanged.icon == "gear")
    }

    @Test("アクティビティタイプカラーテスト")
    func testActivityTypeColors() {
        #expect(ActivityType.joined.color == "green")
        #expect(ActivityType.left.color == "gray")
        #expect(ActivityType.posted.color == "blue")
        #expect(ActivityType.liked.color == "pink")
        #expect(ActivityType.commented.color == "orange")
        #expect(ActivityType.milestone.color == "purple")
        #expect(ActivityType.photoAdded.color == "cyan")
        #expect(ActivityType.settingChanged.color == "gray")
    }

    // MARK: - Formatted Message Tests

    @Test("フォーマットメッセージテスト - 参加")
    func testFormattedMessageJoined() {
        let activity = Activity(
            eventId: "event-1",
            userId: "user-1",
            userName: "山田さん",
            type: .joined
        )

        #expect(activity.formattedMessage == "山田さんさんが参加しました")
    }

    @Test("フォーマットメッセージテスト - 退出")
    func testFormattedMessageLeft() {
        let activity = Activity(
            eventId: "event-1",
            userId: "user-1",
            userName: "山田さん",
            type: .left
        )

        #expect(activity.formattedMessage == "山田さんさんが退出しました")
    }

    @Test("フォーマットメッセージテスト - 投稿")
    func testFormattedMessagePosted() {
        let activity = Activity(
            eventId: "event-1",
            userId: "user-1",
            userName: "山田さん",
            type: .posted
        )

        #expect(activity.formattedMessage == "山田さんさんが投稿しました")
    }

    @Test("フォーマットメッセージテスト - いいね")
    func testFormattedMessageLiked() {
        let activity = Activity(
            eventId: "event-1",
            userId: "user-1",
            userName: "山田さん",
            type: .liked
        )

        #expect(activity.formattedMessage == "山田さんさんがいいねしました")
    }

    @Test("フォーマットメッセージテスト - マイルストーン")
    func testFormattedMessageMilestone() {
        let activity = Activity(
            eventId: "event-1",
            userId: "user-1",
            userName: "山田さん",
            type: .milestone,
            message: "ケーキカット完了！"
        )

        #expect(activity.formattedMessage == "ケーキカット完了！")
    }

    // MARK: - Time Ago Tests

    @Test("時間経過表示テスト")
    func testTimeAgo() {
        let activity = Activity(
            eventId: "event-1",
            userId: "user-1",
            userName: "ユーザー",
            type: .joined,
            createdAt: Date()
        )

        #expect(!activity.timeAgo.isEmpty)
    }

    // MARK: - Equatable Tests

    @Test("アクティビティ等価性テスト")
    func testActivityEquality() {
        let activity1 = Activity(
            id: "activity-1",
            eventId: "event-1",
            userId: "user-1",
            userName: "ユーザー1",
            type: .joined
        )

        let activity2 = Activity(
            id: "activity-1",
            eventId: "event-2",
            userId: "user-2",
            userName: "ユーザー2",
            type: .left
        )

        let activity3 = Activity(
            id: "activity-2",
            eventId: "event-1",
            userId: "user-1",
            userName: "ユーザー1",
            type: .joined
        )

        #expect(activity1 == activity2)
        #expect(activity1 != activity3)
    }

    // MARK: - Sample Data Tests

    @Test("サンプルアクティビティデータ存在確認")
    func testSampleActivitiesExist() {
        #expect(!Activity.sampleActivities.isEmpty)
        #expect(Activity.sampleActivities.count >= 3)
    }
}
