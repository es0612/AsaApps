import Testing
import Foundation
@testable import AsaPapaHubKit

@Suite("MorningRoutineViewModel テスト")
struct MorningRoutineViewModelTests {
    @Test("初期状態")
    @MainActor func testInitialState() {
        let vm = MorningRoutineViewModel(
            routineService: MockMorningRoutineService(),
            scoreCalculator: MockScoreCalculator()
        )
        #expect(vm.routine == nil)
        #expect(vm.currentItemIndex == 0)
        #expect(vm.isRoutineActive == false)
        #expect(vm.elapsedSeconds == 0)
        #expect(vm.isLoading == false)
    }

    @Test("ルーティン読み込み - デフォルト作成")
    @MainActor func testLoadRoutineCreatesDefault() async {
        let service = MockMorningRoutineService()
        let vm = MorningRoutineViewModel(routineService: service, scoreCalculator: MockScoreCalculator())
        await vm.loadRoutine()
        #expect(vm.routine != nil)
        #expect(vm.routine?.items.count == 3)
        #expect(vm.isLoading == false)
    }

    @Test("ルーティン読み込み - 既存取得")
    @MainActor func testLoadExistingRoutine() async {
        let service = MockMorningRoutineService()
        let routine = MorningRoutine(date: Date())
        service.routines = [routine]
        let vm = MorningRoutineViewModel(routineService: service, scoreCalculator: MockScoreCalculator())
        await vm.loadRoutine()
        #expect(vm.routine != nil)
    }

    @Test("ルーティン開始")
    @MainActor func testStartRoutine() async {
        let service = MockMorningRoutineService()
        let vm = MorningRoutineViewModel(routineService: service, scoreCalculator: MockScoreCalculator())
        await vm.loadRoutine()
        await vm.startRoutine()
        #expect(vm.isRoutineActive)
        #expect(service.startRoutineCalled)
    }

    @Test("アイテム完了")
    @MainActor func testCompleteCurrentItem() async {
        let service = MockMorningRoutineService()
        let vm = MorningRoutineViewModel(routineService: service, scoreCalculator: MockScoreCalculator())
        await vm.loadRoutine()
        await vm.startRoutine()
        await vm.completeCurrentItem()
        #expect(service.completeItemCalled)
        #expect(vm.currentItemIndex == 1)
    }

    @Test("アイテムスキップ")
    @MainActor func testSkipCurrentItem() async {
        let service = MockMorningRoutineService()
        let vm = MorningRoutineViewModel(routineService: service, scoreCalculator: MockScoreCalculator())
        await vm.loadRoutine()
        await vm.startRoutine()
        await vm.skipCurrentItem()
        #expect(service.skipItemCalled)
        #expect(vm.currentItemIndex == 1)
    }

    @Test("ルーティン終了")
    @MainActor func testFinishRoutine() async {
        let service = MockMorningRoutineService()
        let scoreCalc = MockScoreCalculator()
        scoreCalc.morningScoreToReturn = 95
        let vm = MorningRoutineViewModel(routineService: service, scoreCalculator: scoreCalc)
        await vm.loadRoutine()
        await vm.startRoutine()
        await vm.finishRoutine()
        #expect(service.finishRoutineCalled)
        #expect(vm.isRoutineActive == false)
    }

    @Test("エラーハンドリング - 読み込み")
    @MainActor func testLoadError() async {
        let service = MockMorningRoutineService()
        service.shouldThrowError = true
        let vm = MorningRoutineViewModel(routineService: service, scoreCalculator: MockScoreCalculator())
        await vm.loadRoutine()
        #expect(vm.error != nil)
    }

    @Test("ルーティンなしでの開始は無効")
    @MainActor func testStartWithoutRoutine() async {
        let service = MockMorningRoutineService()
        let vm = MorningRoutineViewModel(routineService: service, scoreCalculator: MockScoreCalculator())
        await vm.startRoutine()
        #expect(vm.isRoutineActive == false)
        #expect(!service.startRoutineCalled)
    }

    @Test("isLoading状態遷移")
    @MainActor func testLoadingState() async {
        let vm = MorningRoutineViewModel(
            routineService: MockMorningRoutineService(),
            scoreCalculator: MockScoreCalculator()
        )
        #expect(vm.isLoading == false)
        await vm.loadRoutine()
        #expect(vm.isLoading == false)
    }

    @Test("完了後のスコア計算")
    @MainActor func testScoreAfterFinish() async {
        let service = MockMorningRoutineService()
        let scoreCalc = MockScoreCalculator()
        scoreCalc.morningScoreToReturn = 88
        let vm = MorningRoutineViewModel(routineService: service, scoreCalculator: scoreCalc)
        await vm.loadRoutine()
        await vm.startRoutine()
        await vm.finishRoutine()
        #expect(vm.routine?.totalScore == 88)
    }
}
