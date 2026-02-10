import Testing
import Foundation
@testable import AsaEduGameKit

// MARK: - ShapePuzzleViewModel テスト

@Suite("ShapePuzzleViewModel テスト")
struct ShapePuzzleViewModelTests {

    @Test("初期状態")
    @MainActor
    func testInitialState() {
        let vm = ShapePuzzleViewModel()
        #expect(vm.currentShapeName == "")
        #expect(vm.shapeOptions.isEmpty)
        #expect(vm.highlightedShape == nil)
    }

    @Test("図形識別問題セットアップ")
    @MainActor
    func testShapeIdentificationSetup() {
        let vm = ShapePuzzleViewModel()
        let question = GameQuestion(
            questionType: .shapeIdentification,
            questionText: "⭕ このかたちはなに？",
            options: ["まる", "さんかく", "しかく", "ほし"],
            correctAnswer: "まる"
        )
        vm.setupForQuestion(question)
        #expect(vm.currentShapeName == "まる")
        #expect(vm.shapeOptions.count == 4)
        #expect(vm.highlightedShape == nil)
    }

    @Test("パターン問題セットアップ")
    @MainActor
    func testShapePatternSetup() {
        let vm = ShapePuzzleViewModel()
        let question = GameQuestion(
            questionType: .shapePattern,
            questionText: "つぎにくるかたちは？\n⭕🔺⭕🔺⭕?",
            options: ["🔺", "⭕", "🟦", "⭐"],
            correctAnswer: "🔺"
        )
        vm.setupForQuestion(question)
        #expect(vm.currentShapeName == "つぎにくるかたちは？\n⭕🔺⭕🔺⭕?")
        #expect(vm.shapeOptions.count == 4)
    }

    @Test("組み合わせ問題セットアップ")
    @MainActor
    func testShapeCombinationSetup() {
        let vm = ShapePuzzleViewModel()
        let question = GameQuestion(
            questionType: .shapeCombination,
            questionText: "🔺と🔻をあわせると？",
            options: ["ひしがた", "さんかく", "しかく", "まる"],
            correctAnswer: "ひしがた"
        )
        vm.setupForQuestion(question)
        #expect(vm.currentShapeName == "🔺と🔻をあわせると？")
        #expect(vm.shapeOptions.count == 4)
    }

    @Test("ハイライト設定")
    @MainActor
    func testHighlightedShape() {
        let vm = ShapePuzzleViewModel()
        vm.highlightedShape = "まる"
        #expect(vm.highlightedShape == "まる")

        // setupForQuestion でリセット
        let question = GameQuestion(
            questionType: .shapeIdentification,
            questionText: "テスト",
            options: ["a", "b", "c", "d"],
            correctAnswer: "a"
        )
        vm.setupForQuestion(question)
        #expect(vm.highlightedShape == nil)
    }

    @Test("オプション設定")
    @MainActor
    func testOptionsSetup() {
        let vm = ShapePuzzleViewModel()
        let options = ["まる", "さんかく", "しかく", "ほし"]
        let question = GameQuestion(
            questionType: .shapeIdentification,
            questionText: "テスト",
            options: options,
            correctAnswer: "まる"
        )
        vm.setupForQuestion(question)
        #expect(vm.shapeOptions == options)
    }

    @Test("図形名の取得")
    @MainActor
    func testShapeNameRetrieval() {
        let vm = ShapePuzzleViewModel()
        let question = GameQuestion(
            questionType: .shapeIdentification,
            questionText: "⭕ このかたちはなに？",
            options: ["まる", "さんかく", "しかく", "ほし"],
            correctAnswer: "まる"
        )
        vm.setupForQuestion(question)
        // shapeIdentification では correctAnswer が currentShapeName
        #expect(vm.currentShapeName == "まる")
    }

    @Test("問題切り替え")
    @MainActor
    func testQuestionSwitch() {
        let vm = ShapePuzzleViewModel()

        // 1問目
        let q1 = GameQuestion(
            questionType: .shapeIdentification,
            questionText: "⭕ このかたちはなに？",
            options: ["まる", "さんかく", "しかく", "ほし"],
            correctAnswer: "まる"
        )
        vm.setupForQuestion(q1)
        #expect(vm.currentShapeName == "まる")

        // 2問目に切り替え
        let q2 = GameQuestion(
            questionType: .shapeIdentification,
            questionText: "🔺 このかたちはなに？",
            options: ["まる", "さんかく", "しかく", "ほし"],
            correctAnswer: "さんかく"
        )
        vm.setupForQuestion(q2)
        #expect(vm.currentShapeName == "さんかく")
        #expect(vm.highlightedShape == nil)
    }
}
