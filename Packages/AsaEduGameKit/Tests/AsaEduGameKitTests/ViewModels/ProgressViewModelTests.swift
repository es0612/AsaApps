import Testing
import Foundation
import SwiftData
@testable import AsaEduGameKit

// MARK: - ProgressViewModel テスト

@Suite("ProgressViewModel テスト")
struct ProgressViewModelTests {

    @Test("初期状態")
    @MainActor
    func testInitialState() {
        let dataService = EduGameDataService(inMemory: true)
        let vm = ProgressViewModel(dataService: dataService)
        #expect(vm.profile == nil)
        #expect(vm.recentSessions.isEmpty)
        #expect(vm.modeStats.isEmpty)
        #expect(vm.isLoading == false)
    }

    @Test("プログレス読み込み")
    @MainActor
    func testLoadProgress() throws {
        let dataService = EduGameDataService(inMemory: true)
        let vm = ProgressViewModel(dataService: dataService)

        // プロフィールとセッションを作成
        let profile = try dataService.getOrCreateProfile()
        let session = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )
        session.correctAnswers = 4

        vm.loadProgress()
        #expect(vm.profile != nil)
        #expect(vm.recentSessions.count == 1)
        #expect(!vm.modeStats.isEmpty)
    }

    @Test("モード統計計算 - 算数")
    @MainActor
    func testModeStatsMath() throws {
        let dataService = EduGameDataService(inMemory: true)
        let vm = ProgressViewModel(dataService: dataService)

        let profile = try dataService.getOrCreateProfile()
        let session = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )
        session.correctAnswers = 4
        session.maxCombo = 3

        vm.loadProgress()

        let mathStats = vm.modeStats[.mathQuiz]
        #expect(mathStats != nil)
        #expect(mathStats!.totalSessions == 1)
        #expect(mathStats!.totalCorrect == 4)
        #expect(mathStats!.totalQuestions == 5)
        #expect(mathStats!.bestCombo == 3)
    }

    @Test("モード統計計算 - 複数モード")
    @MainActor
    func testModeStatsMultipleModes() throws {
        let dataService = EduGameDataService(inMemory: true)
        let vm = ProgressViewModel(dataService: dataService)

        let profile = try dataService.getOrCreateProfile()

        let s1 = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )
        s1.correctAnswers = 4

        let s2 = try dataService.createSession(
            profile: profile, gameMode: .hiraganaPractice, difficulty: .normal, totalQuestions: 8
        )
        s2.correctAnswers = 6

        vm.loadProgress()

        #expect(vm.modeStats[.mathQuiz]?.totalSessions == 1)
        #expect(vm.modeStats[.hiraganaPractice]?.totalSessions == 1)
        #expect(vm.modeStats[.shapePuzzle]?.totalSessions == 0)
    }

    @Test("最近のセッション取得")
    @MainActor
    func testRecentSessions() throws {
        let dataService = EduGameDataService(inMemory: true)
        let vm = ProgressViewModel(dataService: dataService)

        let profile = try dataService.getOrCreateProfile()

        // 3つのセッションを作成
        for mode in [GameMode.mathQuiz, .hiraganaPractice, .shapePuzzle] {
            _ = try dataService.createSession(
                profile: profile, gameMode: mode, difficulty: .easy, totalQuestions: 5
            )
        }

        vm.loadProgress()
        #expect(vm.recentSessions.count == 3)
    }

    @Test("平均正答率計算")
    @MainActor
    func testAverageAccuracy() throws {
        let dataService = EduGameDataService(inMemory: true)
        let vm = ProgressViewModel(dataService: dataService)

        let profile = try dataService.getOrCreateProfile()

        let s1 = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 10
        )
        s1.correctAnswers = 8

        let s2 = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 10
        )
        s2.correctAnswers = 6

        vm.loadProgress()

        let mathStats = vm.modeStats[.mathQuiz]
        #expect(mathStats != nil)
        // 平均正答率: (8+6) / (10+10) = 14/20 = 0.7
        #expect(mathStats!.averageAccuracy == 0.7)
    }

    @Test("ベストコンボ取得")
    @MainActor
    func testBestCombo() throws {
        let dataService = EduGameDataService(inMemory: true)
        let vm = ProgressViewModel(dataService: dataService)

        let profile = try dataService.getOrCreateProfile()

        let s1 = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )
        s1.maxCombo = 3

        let s2 = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .normal, totalQuestions: 8
        )
        s2.maxCombo = 7

        vm.loadProgress()

        let mathStats = vm.modeStats[.mathQuiz]
        #expect(mathStats!.bestCombo == 7)
    }

    @Test("セッションなし時の統計")
    @MainActor
    func testEmptyStats() throws {
        let dataService = EduGameDataService(inMemory: true)
        let vm = ProgressViewModel(dataService: dataService)

        vm.loadProgress()

        // プロフィールは自動作成される
        #expect(vm.profile != nil)
        #expect(vm.recentSessions.isEmpty)

        // 各モードの統計は空の状態
        for mode in GameMode.allCases {
            let stats = vm.modeStats[mode]
            #expect(stats != nil)
            #expect(stats!.totalSessions == 0)
            #expect(stats!.totalCorrect == 0)
            #expect(stats!.averageAccuracy == 0.0)
            #expect(stats!.bestCombo == 0)
        }
    }
}
