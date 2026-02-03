//
//  AsaCrowdsourceTests.swift
//  AsaCrowdsourceTests
//
//  AsaCrowdsourceのテスト
//

import Testing
import Foundation
@testable import AsaCrowdsource

// MARK: - IdeaCategory Tests

@Suite("IdeaCategory Tests")
struct IdeaCategoryTests {

    @Test("カテゴリの表示名が正しい")
    func testDisplayNames() {
        #expect(IdeaCategory.familyTrip.displayName == "家族旅行")
        #expect(IdeaCategory.weekend.displayName == "週末の過ごし方")
        #expect(IdeaCategory.parenting.displayName == "子育て")
        #expect(IdeaCategory.shopping.displayName == "買い物")
        #expect(IdeaCategory.homeImprovement.displayName == "住まい")
        #expect(IdeaCategory.meal.displayName == "食事・レシピ")
        #expect(IdeaCategory.event.displayName == "イベント")
        #expect(IdeaCategory.health.displayName == "健康・運動")
        #expect(IdeaCategory.other.displayName == "その他")
    }

    @Test("カテゴリの絵文字が正しい")
    func testEmojis() {
        #expect(IdeaCategory.familyTrip.emoji == "✈️")
        #expect(IdeaCategory.weekend.emoji == "☀️")
        #expect(IdeaCategory.parenting.emoji == "👨‍👩‍👧")
        #expect(IdeaCategory.shopping.emoji == "🛒")
        #expect(IdeaCategory.health.emoji == "❤️")
        #expect(IdeaCategory.other.emoji == "💡")
    }

    @Test("全てのカテゴリがCaseIterableに含まれる")
    func testAllCases() {
        #expect(IdeaCategory.allCases.count == 9)
    }
}

// MARK: - IdeaStatus Tests

@Suite("IdeaStatus Tests")
struct IdeaStatusTests {

    @Test("ステータスの表示名が正しい")
    func testDisplayNames() {
        #expect(IdeaStatus.proposed.displayName == "提案中")
        #expect(IdeaStatus.discussing.displayName == "議論中")
        #expect(IdeaStatus.approved.displayName == "承認済み")
        #expect(IdeaStatus.inProgress.displayName == "実行中")
        #expect(IdeaStatus.completed.displayName == "完了")
        #expect(IdeaStatus.archived.displayName == "アーカイブ")
    }

    @Test("ステータス進行が正しい")
    func testStatusProgression() {
        #expect(IdeaStatus.proposed.nextStatus == .discussing)
        #expect(IdeaStatus.discussing.nextStatus == .approved)
        #expect(IdeaStatus.approved.nextStatus == .inProgress)
        #expect(IdeaStatus.inProgress.nextStatus == .completed)
        #expect(IdeaStatus.completed.nextStatus == nil)
        #expect(IdeaStatus.archived.nextStatus == nil)
    }

    @Test("アクティブステータスの判定が正しい")
    func testIsActive() {
        #expect(IdeaStatus.proposed.isActive == true)
        #expect(IdeaStatus.discussing.isActive == true)
        #expect(IdeaStatus.approved.isActive == true)
        #expect(IdeaStatus.inProgress.isActive == true)
        #expect(IdeaStatus.completed.isActive == false)
        #expect(IdeaStatus.archived.isActive == false)
    }

    @Test("進行可能かの判定が正しい")
    func testCanProgress() {
        #expect(IdeaStatus.proposed.canProgress == true)
        #expect(IdeaStatus.discussing.canProgress == true)
        #expect(IdeaStatus.completed.canProgress == false)
        #expect(IdeaStatus.archived.canProgress == false)
    }
}

// MARK: - VoteType Tests

@Suite("VoteType Tests")
struct VoteTypeTests {

    @Test("投票タイプの表示名が正しい")
    func testDisplayNames() {
        #expect(VoteType.like.displayName == "いいね")
        #expect(VoteType.love.displayName == "大好き")
        #expect(VoteType.interested.displayName == "興味あり")
    }

    @Test("投票タイプの重みが正しい")
    func testWeights() {
        #expect(VoteType.like.weight == 1)
        #expect(VoteType.love.weight == 3)
        #expect(VoteType.interested.weight == 2)
    }

    @Test("投票タイプの絵文字が正しい")
    func testEmojis() {
        #expect(VoteType.like.emoji == "👍")
        #expect(VoteType.love.emoji == "❤️")
        #expect(VoteType.interested.emoji == "🤔")
    }
}

// MARK: - VoteSummary Tests

@Suite("VoteSummary Tests")
struct VoteSummaryTests {

    @Test("空のサマリーが正しい")
    func testEmptySummary() {
        let summary = VoteSummary.empty
        #expect(summary.totalCount == 0)
        #expect(summary.weightedScore == 0)
    }

    @Test("カウントの計算が正しい")
    func testTotalCount() {
        let summary = VoteSummary(likeCount: 3, loveCount: 2, interestedCount: 1)
        #expect(summary.totalCount == 6)
    }

    @Test("重み付けスコアの計算が正しい")
    func testWeightedScore() {
        let summary = VoteSummary(likeCount: 3, loveCount: 2, interestedCount: 1)
        // 3*1 + 2*3 + 1*2 = 3 + 6 + 2 = 11
        #expect(summary.weightedScore == 11)
    }
}

// MARK: - MemberRole Tests

@Suite("MemberRole Tests")
struct MemberRoleTests {

    @Test("ロールの表示名が正しい")
    func testDisplayNames() {
        #expect(MemberRole.owner.displayName == "オーナー")
        #expect(MemberRole.member.displayName == "メンバー")
    }

    @Test("ロールの絵文字が正しい")
    func testEmojis() {
        #expect(MemberRole.owner.emoji == "👑")
        #expect(MemberRole.member.emoji == "👤")
    }
}

// MARK: - LocalFamilyGroup Tests

@Suite("LocalFamilyGroup Tests")
struct LocalFamilyGroupTests {

    @Test("招待コードの生成が6文字")
    func testInviteCodeLength() {
        let code = LocalFamilyGroup.generateInviteCode()
        #expect(code.count == 6)
    }

    @Test("招待コードが英数字のみ")
    func testInviteCodeCharacters() {
        let code = LocalFamilyGroup.generateInviteCode()
        let allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        #expect(code.unicodeScalars.allSatisfy { allowedCharacters.contains($0) })
    }

    @Test("グループ初期化が正しい")
    func testGroupInitialization() {
        let group = LocalFamilyGroup(
            name: "テストグループ",
            groupDescription: "テスト用",
            ownerId: "owner123"
        )
        #expect(group.name == "テストグループ")
        #expect(group.groupDescription == "テスト用")
        #expect(group.ownerId == "owner123")
        #expect(group.maxMembers == 10)
        #expect(group.inviteCode.count == 6)
    }
}

// MARK: - User Tests

@Suite("User Tests")
struct UserTests {

    @Test("ユーザー初期化が正しい")
    func testUserInitialization() {
        let user = User(
            id: "user123",
            email: "test@example.com",
            displayName: "テストユーザー"
        )
        #expect(user.id == "user123")
        #expect(user.email == "test@example.com")
        #expect(user.displayName == "テストユーザー")
    }

    @Test("サンプルユーザーが正しい")
    func testSampleUser() {
        let sample = User.sampleUser
        #expect(sample.id == "user1")
        #expect(sample.displayName == "パパ")
    }

    @Test("匿名ユーザーが正しい")
    func testAnonymousUser() {
        let anonymous = User.anonymous
        #expect(anonymous.id == "anonymous")
        #expect(anonymous.displayName == "ゲスト")
        #expect(anonymous.email.isEmpty)
    }
}

// MARK: - DataServiceError Tests

@Suite("DataServiceError Tests")
struct DataServiceErrorTests {

    @Test("エラーメッセージが正しい")
    func testErrorMessages() {
        #expect(DataServiceError.groupNotFound.errorDescription == "グループが見つかりません")
        #expect(DataServiceError.ideaNotFound.errorDescription == "アイデアが見つかりません")
        #expect(DataServiceError.invalidInviteCode.errorDescription == "招待コードが無効です")
        #expect(DataServiceError.maxMembersReached.errorDescription == "メンバー数が上限に達しています")
        #expect(DataServiceError.alreadyMember.errorDescription == "既にこのグループのメンバーです")
        #expect(DataServiceError.notAuthorized.errorDescription == "この操作を行う権限がありません")
    }
}
