import Testing
import Foundation
@testable import AsaEduGameKit

// MARK: - QuestionGenerator テスト

@Suite("QuestionGenerator テスト")
struct QuestionGeneratorTests {

    let generator = QuestionGeneratorService()

    // MARK: - 算数問題生成

    @Test("算数問題生成 - easy")
    func testMathQuizEasy() {
        let questions = generator.generateQuestions(mode: .mathQuiz, difficulty: .easy, count: 5)
        #expect(questions.count == 5)
        for question in questions {
            #expect(question.options.count == 4)
            #expect(question.options.contains(question.correctAnswer))
            #expect(question.questionType.gameMode == .mathQuiz)
        }
    }

    @Test("算数問題生成 - normal")
    func testMathQuizNormal() {
        let questions = generator.generateQuestions(mode: .mathQuiz, difficulty: .normal, count: 8)
        #expect(questions.count == 8)
        for question in questions {
            #expect(question.options.count == 4)
            #expect(question.options.contains(question.correctAnswer))
        }
    }

    @Test("算数問題生成 - hard")
    func testMathQuizHard() {
        let questions = generator.generateQuestions(mode: .mathQuiz, difficulty: .hard, count: 10)
        #expect(questions.count == 10)
        for question in questions {
            #expect(question.options.count == 4)
            #expect(question.options.contains(question.correctAnswer))
        }
    }

    // MARK: - ひらがな問題生成

    @Test("ひらがな問題生成 - easy")
    func testHiraganaEasy() {
        let questions = generator.generateQuestions(mode: .hiraganaPractice, difficulty: .easy, count: 5)
        #expect(questions.count == 5)
        for question in questions {
            #expect(question.options.count == 4)
            #expect(question.options.contains(question.correctAnswer))
            #expect(question.questionType.gameMode == .hiraganaPractice)
        }
    }

    @Test("ひらがな問題生成 - normal")
    func testHiraganaNormal() {
        let questions = generator.generateQuestions(mode: .hiraganaPractice, difficulty: .normal, count: 8)
        #expect(questions.count == 8)
        for question in questions {
            #expect(question.options.count == 4)
            #expect(question.options.contains(question.correctAnswer))
        }
    }

    @Test("ひらがな問題生成 - hard")
    func testHiraganaHard() {
        let questions = generator.generateQuestions(mode: .hiraganaPractice, difficulty: .hard, count: 10)
        #expect(questions.count == 10)
        for question in questions {
            #expect(question.options.count == 4)
            #expect(question.options.contains(question.correctAnswer))
        }
    }

    // MARK: - 図形問題生成

    @Test("図形問題生成 - easy")
    func testShapePuzzleEasy() {
        let questions = generator.generateQuestions(mode: .shapePuzzle, difficulty: .easy, count: 5)
        #expect(questions.count == 5)
        for question in questions {
            #expect(question.options.count == 4)
            #expect(question.options.contains(question.correctAnswer))
            #expect(question.questionType.gameMode == .shapePuzzle)
        }
    }

    @Test("図形問題生成 - normal")
    func testShapePuzzleNormal() {
        let questions = generator.generateQuestions(mode: .shapePuzzle, difficulty: .normal, count: 8)
        #expect(questions.count == 8)
        for question in questions {
            #expect(question.options.count == 4)
            #expect(question.options.contains(question.correctAnswer))
        }
    }

    @Test("図形問題生成 - hard")
    func testShapePuzzleHard() {
        let questions = generator.generateQuestions(mode: .shapePuzzle, difficulty: .hard, count: 10)
        #expect(questions.count == 10)
        for question in questions {
            #expect(question.options.count == 4)
            #expect(question.options.contains(question.correctAnswer))
        }
    }

    // MARK: - 論理問題生成

    @Test("論理問題生成 - easy")
    func testLogicGameEasy() {
        let questions = generator.generateQuestions(mode: .logicGame, difficulty: .easy, count: 5)
        #expect(questions.count == 5)
        for question in questions {
            #expect(question.options.count == 4)
            #expect(question.options.contains(question.correctAnswer))
            #expect(question.questionType.gameMode == .logicGame)
        }
    }

    @Test("論理問題生成 - normal")
    func testLogicGameNormal() {
        let questions = generator.generateQuestions(mode: .logicGame, difficulty: .normal, count: 8)
        #expect(questions.count == 8)
        for question in questions {
            #expect(question.options.count == 4)
            #expect(question.options.contains(question.correctAnswer))
        }
    }

    @Test("論理問題生成 - hard")
    func testLogicGameHard() {
        let questions = generator.generateQuestions(mode: .logicGame, difficulty: .hard, count: 10)
        #expect(questions.count == 10)
        for question in questions {
            #expect(question.options.count == 4)
            #expect(question.options.contains(question.correctAnswer))
        }
    }

    // MARK: - 共通テスト

    @Test("問題数指定")
    func testQuestionCount() {
        let questions = generator.generateQuestions(mode: .mathQuiz, difficulty: .easy, count: 10)
        #expect(questions.count == 10)
    }

    @Test("選択肢に正解が含まれる")
    func testCorrectAnswerInOptions() {
        // 全モードで正解が選択肢に含まれることを確認
        for mode in GameMode.allCases {
            let questions = generator.generateQuestions(mode: mode, difficulty: .easy, count: 5)
            for question in questions {
                #expect(question.options.contains(question.correctAnswer))
            }
        }
    }

    @Test("選択肢が4つ")
    func testFourOptions() {
        // 全モードで選択肢が4つであることを確認
        for mode in GameMode.allCases {
            let questions = generator.generateQuestions(mode: mode, difficulty: .normal, count: 5)
            for question in questions {
                #expect(question.options.count == 4)
            }
        }
    }

    // MARK: - 個別問題生成

    @Test("個別問題生成 - addition")
    func testGenerateAddition() {
        let question = generator.generateQuestion(type: .addition, difficulty: .easy)
        #expect(question.questionType == .addition)
        #expect(question.questionText.contains("+"))
        #expect(question.options.count == 4)
        #expect(question.options.contains(question.correctAnswer))
    }

    @Test("個別問題生成 - hiraganaReading")
    func testGenerateHiraganaReading() {
        let question = generator.generateQuestion(type: .hiraganaReading, difficulty: .easy)
        #expect(question.questionType == .hiraganaReading)
        #expect(question.options.count == 4)
        #expect(question.options.contains(question.correctAnswer))
    }

    @Test("個別問題生成 - shapeIdentification")
    func testGenerateShapeIdentification() {
        let question = generator.generateQuestion(type: .shapeIdentification, difficulty: .easy)
        #expect(question.questionType == .shapeIdentification)
        #expect(question.options.count == 4)
        #expect(question.options.contains(question.correctAnswer))
    }

    @Test("個別問題生成 - oddOneOut")
    func testGenerateOddOneOut() {
        let question = generator.generateQuestion(type: .oddOneOut, difficulty: .easy)
        #expect(question.questionType == .oddOneOut)
        #expect(question.options.count == 4)
        #expect(question.options.contains(question.correctAnswer))
    }

    @Test("問題のランダム性")
    func testRandomness() {
        // 同条件で2回生成して完全一致しないことを確認（ランダム性テスト）
        let questions1 = generator.generateQuestions(mode: .mathQuiz, difficulty: .easy, count: 10)
        let questions2 = generator.generateQuestions(mode: .mathQuiz, difficulty: .easy, count: 10)

        let texts1 = questions1.map(\.questionText)
        let texts2 = questions2.map(\.questionText)

        // 完全一致する確率は非常に低いので、ほぼ必ず異なるはず
        #expect(texts1 != texts2)
    }
}
