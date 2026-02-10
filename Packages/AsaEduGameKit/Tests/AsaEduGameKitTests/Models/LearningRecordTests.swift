import Testing
import Foundation
@testable import AsaEduGameKit

// MARK: - LearningRecord テスト

@Suite("LearningRecord テスト")
struct LearningRecordTests {

    @Test("デフォルト初期化")
    func testDefaultInit() {
        let record = LearningRecord()
        #expect(record.questionType == .addition)
        #expect(record.questionContent == "")
        #expect(record.userAnswer == "")
        #expect(record.correctAnswer == "")
        #expect(record.isCorrect == false)
        #expect(record.responseTimeSeconds == 0)
    }

    @Test("正解記録")
    func testCorrectRecord() {
        let record = LearningRecord(
            questionType: .addition,
            questionContent: "3 + 2 = ?",
            userAnswer: "5",
            correctAnswer: "5",
            isCorrect: true,
            responseTimeSeconds: 3.5
        )
        #expect(record.isCorrect == true)
        #expect(record.userAnswer == "5")
        #expect(record.correctAnswer == "5")
    }

    @Test("不正解記録")
    func testIncorrectRecord() {
        let record = LearningRecord(
            questionType: .subtraction,
            questionContent: "5 - 3 = ?",
            userAnswer: "3",
            correctAnswer: "2",
            isCorrect: false,
            responseTimeSeconds: 5.0
        )
        #expect(record.isCorrect == false)
        #expect(record.userAnswer == "3")
        #expect(record.correctAnswer == "2")
    }

    @Test("問題タイプ computed property")
    func testQuestionTypeComputedProperty() {
        let record = LearningRecord(questionType: .hiraganaReading)
        #expect(record.questionType == .hiraganaReading)
        #expect(record.questionTypeRawValue == "hiraganaReading")

        // setter テスト
        record.questionType = .shapeIdentification
        #expect(record.questionType == .shapeIdentification)
        #expect(record.questionTypeRawValue == "shapeIdentification")
    }

    @Test("回答時間記録")
    func testResponseTime() {
        let record = LearningRecord(
            questionType: .addition,
            questionContent: "1 + 1 = ?",
            userAnswer: "2",
            correctAnswer: "2",
            isCorrect: true,
            responseTimeSeconds: 12.5
        )
        #expect(record.responseTimeSeconds == 12.5)
    }

    @Test("全問題タイプの記録")
    func testAllQuestionTypes() {
        // 13種類全ての問題タイプで記録が作成できることを確認
        for questionType in QuestionType.allCases {
            let record = LearningRecord(questionType: questionType)
            #expect(record.questionType == questionType)
            #expect(record.questionTypeRawValue == questionType.rawValue)
        }
        #expect(QuestionType.allCases.count == 13)
    }
}
