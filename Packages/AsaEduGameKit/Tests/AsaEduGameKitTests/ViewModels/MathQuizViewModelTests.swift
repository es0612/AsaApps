import Testing
import Foundation
@testable import AsaEduGameKit

// MARK: - MathQuizViewModel テスト

@Suite("MathQuizViewModel テスト")
struct MathQuizViewModelTests {

    @Test("初期状態")
    @MainActor
    func testInitialState() {
        let vm = MathQuizViewModel()
        #expect(vm.currentExpression == "")
        #expect(vm.answerOptions.isEmpty)
        #expect(vm.operationType == "+")
    }

    @Test("加法問題セットアップ")
    @MainActor
    func testAdditionSetup() {
        let vm = MathQuizViewModel()
        let question = GameQuestion(
            questionType: .addition,
            questionText: "3 + 2 = ?",
            options: ["4", "5", "6", "7"],
            correctAnswer: "5"
        )
        vm.setupForQuestion(question)
        #expect(vm.currentExpression == "3 + 2 = ?")
        #expect(vm.operationType == "+")
    }

    @Test("減法問題セットアップ")
    @MainActor
    func testSubtractionSetup() {
        let vm = MathQuizViewModel()
        let question = GameQuestion(
            questionType: .subtraction,
            questionText: "5 - 3 = ?",
            options: ["1", "2", "3", "4"],
            correctAnswer: "2"
        )
        vm.setupForQuestion(question)
        #expect(vm.currentExpression == "5 - 3 = ?")
        #expect(vm.operationType == "-")
    }

    @Test("比較問題セットアップ")
    @MainActor
    func testComparisonSetup() {
        let vm = MathQuizViewModel()
        let question = GameQuestion(
            questionType: .comparison,
            questionText: "5 と 3、おおきいのはどっち？",
            options: ["3", "5", "8", "2"],
            correctAnswer: "5"
        )
        vm.setupForQuestion(question)
        #expect(vm.operationType == ">")
    }

    @Test("穴埋め問題セットアップ")
    @MainActor
    func testFillInBlankSetup() {
        let vm = MathQuizViewModel()
        let question = GameQuestion(
            questionType: .fillInBlank,
            questionText: "? + 3 = 5",
            options: ["1", "2", "3", "4"],
            correctAnswer: "2"
        )
        vm.setupForQuestion(question)
        #expect(vm.currentExpression == "? + 3 = 5")
        #expect(vm.operationType == "?")
    }

    @Test("数式フォーマット - 足し算")
    @MainActor
    func testFormatExpressionAddition() {
        let vm = MathQuizViewModel()
        let question = GameQuestion(
            questionType: .addition,
            questionText: "7 + 3 = ?",
            options: ["8", "9", "10", "11"],
            correctAnswer: "10"
        )
        let formatted = vm.formatExpression(from: question)
        #expect(formatted == "7 + 3 = ?")
    }

    @Test("数式フォーマット - 引き算")
    @MainActor
    func testFormatExpressionSubtraction() {
        let vm = MathQuizViewModel()
        let question = GameQuestion(
            questionType: .subtraction,
            questionText: "8 - 3 = ?",
            options: ["3", "4", "5", "6"],
            correctAnswer: "5"
        )
        let formatted = vm.formatExpression(from: question)
        #expect(formatted == "8 - 3 = ?")
    }

    @Test("数式フォーマット - 比較")
    @MainActor
    func testFormatExpressionComparison() {
        let vm = MathQuizViewModel()
        let question = GameQuestion(
            questionType: .comparison,
            questionText: "10 と 7、おおきいのはどっち？",
            options: ["7", "10", "17", "3"],
            correctAnswer: "10"
        )
        let formatted = vm.formatExpression(from: question)
        #expect(formatted == "10 と 7、おおきいのはどっち？")
    }

    @Test("数式フォーマット - 穴埋め")
    @MainActor
    func testFormatExpressionFillInBlank() {
        let vm = MathQuizViewModel()
        let question = GameQuestion(
            questionType: .fillInBlank,
            questionText: "? + 4 = 7",
            options: ["2", "3", "4", "5"],
            correctAnswer: "3"
        )
        let formatted = vm.formatExpression(from: question)
        #expect(formatted == "? + 4 = 7")
    }

    @Test("選択肢の設定")
    @MainActor
    func testAnswerOptionsSetup() {
        let vm = MathQuizViewModel()
        let question = GameQuestion(
            questionType: .addition,
            questionText: "2 + 3 = ?",
            options: ["3", "4", "5", "6"],
            correctAnswer: "5"
        )
        vm.setupForQuestion(question)
        #expect(vm.answerOptions.count == 4)
        #expect(vm.answerOptions.contains(5))
    }
}
