import Testing
import Foundation
import SwiftData
@testable import AsaEduGameKit

// MARK: - ProfileViewModel テスト

@Suite("ProfileViewModel テスト")
struct ProfileViewModelTests {

    @Test("初期状態")
    @MainActor
    func testInitialState() {
        let dataService = EduGameDataService(inMemory: true)
        let vm = ProfileViewModel(dataService: dataService)
        #expect(vm.profile == nil)
        #expect(vm.unlockedBadges.isEmpty)
        #expect(vm.isEditing == false)
    }

    @Test("プロフィール読み込み")
    @MainActor
    func testLoadProfile() throws {
        let dataService = EduGameDataService(inMemory: true)
        let vm = ProfileViewModel(dataService: dataService)

        vm.loadProfile()
        #expect(vm.profile != nil)
        #expect(vm.profile!.name == "")
        #expect(vm.profile!.avatarEmoji == "🐱")
    }

    @Test("編集モード開始")
    @MainActor
    func testStartEditing() throws {
        let dataService = EduGameDataService(inMemory: true)
        let vm = ProfileViewModel(dataService: dataService)

        // プロフィール読み込み
        vm.loadProfile()
        #expect(vm.profile != nil)

        // 編集モード開始
        vm.startEditing()
        #expect(vm.isEditing == true)
        #expect(vm.editName == vm.profile!.name)
        #expect(vm.editEmoji == vm.profile!.avatarEmoji)
        #expect(vm.editAge == vm.profile!.age)
    }

    @Test("編集キャンセル")
    @MainActor
    func testCancelEditing() throws {
        let dataService = EduGameDataService(inMemory: true)
        let vm = ProfileViewModel(dataService: dataService)

        vm.loadProfile()
        vm.startEditing()

        // 編集フィールドを変更
        vm.editName = "へんこうご"
        vm.editEmoji = "🐶"
        vm.editAge = 8

        // キャンセル
        vm.cancelEditing()
        #expect(vm.isEditing == false)
        // キャンセル後は元の値に戻る
        #expect(vm.editName == vm.profile!.name)
        #expect(vm.editEmoji == vm.profile!.avatarEmoji)
        #expect(vm.editAge == vm.profile!.age)
    }

    @Test("プロフィール保存")
    @MainActor
    func testSaveProfile() throws {
        let dataService = EduGameDataService(inMemory: true)
        let vm = ProfileViewModel(dataService: dataService)

        vm.loadProfile()
        vm.startEditing()

        // 編集フィールドを変更して保存
        vm.editName = "たろう"
        vm.editEmoji = "🐶"
        vm.editAge = 7

        vm.saveProfile()
        #expect(vm.isEditing == false)
        #expect(vm.profile!.name == "たろう")
        #expect(vm.profile!.avatarEmoji == "🐶")
        #expect(vm.profile!.age == 7)
    }

    @Test("バッジ読み込み")
    @MainActor
    func testLoadBadges() throws {
        let dataService = EduGameDataService(inMemory: true)
        let vm = ProfileViewModel(dataService: dataService)

        // プロフィールにバッジを追加
        let profile = try dataService.getOrCreateProfile()
        _ = try dataService.unlockAchievement(for: profile, badge: .firstStar)
        _ = try dataService.unlockAchievement(for: profile, badge: .combo5)

        vm.loadProfile()
        // 解除済みバッジはプロフィールの achievements から取得
        #expect(vm.unlockedBadges.count == 2)
        // 全バッジ定義は常に13種
        #expect(vm.allBadges.count == 13)
    }
}
