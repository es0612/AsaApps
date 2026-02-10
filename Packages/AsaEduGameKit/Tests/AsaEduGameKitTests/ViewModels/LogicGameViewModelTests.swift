import Testing
import Foundation
@testable import AsaEduGameKit

// MARK: - LogicGameViewModel テスト

@Suite("LogicGameViewModel テスト")
struct LogicGameViewModelTests {

    @Test("初期状態")
    @MainActor
    func testInitialState() {
        let vm = LogicGameViewModel()
        #expect(vm.items.isEmpty)
        #expect(vm.questionSubtype == .oddOneOut)
        #expect(vm.selectedItem == nil)
        #expect(vm.orderedItems.isEmpty)
    }

    @Test("仲間はずれ問題セットアップ")
    @MainActor
    func testOddOneOutSetup() {
        let vm = LogicGameViewModel()
        let question = GameQuestion(
            questionType: .oddOneOut,
            questionText: "なかまはずれはどれ？\n🍎  🍊  🍌  🐶",
            options: ["🍎", "🍊", "🍌", "🐶"],
            correctAnswer: "🐶"
        )
        vm.setupForQuestion(question)
        #expect(vm.questionSubtype == .oddOneOut)
        #expect(vm.items.count == 4)
        #expect(vm.orderedItems.isEmpty)
        #expect(vm.selectedItem == nil)
    }

    @Test("順番問題セットアップ")
    @MainActor
    func testSequenceOrderSetup() {
        let vm = LogicGameViewModel()
        let question = GameQuestion(
            questionType: .sequenceOrder,
            questionText: "つぎのかずは？\n1, 2, 3, ?",
            options: ["4", "5", "3", "6"],
            correctAnswer: "4"
        )
        vm.setupForQuestion(question)
        #expect(vm.questionSubtype == .sequenceOrder)
        #expect(vm.items.count == 4)
        #expect(vm.orderedItems.count == 4)
    }

    @Test("パターン完成問題セットアップ")
    @MainActor
    func testPatternCompletionSetup() {
        let vm = LogicGameViewModel()
        let question = GameQuestion(
            questionType: .patternCompletion,
            questionText: "?にはいるものは？\n🔴🔵🔴🔵🔴?",
            options: ["🔵", "🔴", "🟢", "🟡"],
            correctAnswer: "🔵"
        )
        vm.setupForQuestion(question)
        #expect(vm.questionSubtype == .patternCompletion)
        #expect(vm.items.count == 4)
        #expect(vm.orderedItems.isEmpty)
    }

    @Test("アイテム選択")
    @MainActor
    func testItemSelection() {
        let vm = LogicGameViewModel()
        vm.selectedItem = "🐶"
        #expect(vm.selectedItem == "🐶")
    }

    @Test("アイテム並べ替え")
    @MainActor
    func testReorderItem() {
        let vm = LogicGameViewModel()
        let question = GameQuestion(
            questionType: .sequenceOrder,
            questionText: "テスト",
            options: ["A", "B", "C", "D"],
            correctAnswer: "A"
        )
        vm.setupForQuestion(question)

        // インデックス0のアイテムをインデックス2に移動
        vm.reorderItem(from: 0, to: 2)
        #expect(vm.orderedItems[0] == "B")
        #expect(vm.orderedItems[2] == "A")
    }

    @Test("問題サブタイプ設定")
    @MainActor
    func testQuestionSubtypeSetting() {
        let vm = LogicGameViewModel()

        let question1 = GameQuestion(
            questionType: .oddOneOut,
            questionText: "テスト",
            options: ["A", "B", "C", "D"],
            correctAnswer: "D"
        )
        vm.setupForQuestion(question1)
        #expect(vm.questionSubtype == .oddOneOut)

        let question2 = GameQuestion(
            questionType: .patternCompletion,
            questionText: "テスト",
            options: ["A", "B", "C", "D"],
            correctAnswer: "B"
        )
        vm.setupForQuestion(question2)
        #expect(vm.questionSubtype == .patternCompletion)
    }

    @Test("順序アイテム設定")
    @MainActor
    func testOrderedItemsSetup() {
        let vm = LogicGameViewModel()
        let options = ["3", "1", "4", "2"]
        let question = GameQuestion(
            questionType: .sequenceOrder,
            questionText: "テスト",
            options: options,
            correctAnswer: "1"
        )
        vm.setupForQuestion(question)
        #expect(vm.orderedItems == options)
    }
}
