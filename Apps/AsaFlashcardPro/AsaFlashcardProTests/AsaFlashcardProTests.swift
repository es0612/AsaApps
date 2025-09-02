import XCTest
@testable import AsaFlashcardPro

final class AsaFlashcardProTests: XCTestCase {
    
    // MARK: - Category Tests
    
    func testCategoryInitialization() throws {
        let category = Category(name: "英語基礎", icon: "textbook", color: "AsaCoffeeBrown")
        
        XCTAssertEqual(category.name, "英語基礎")
        XCTAssertEqual(category.icon, "textbook")
        XCTAssertEqual(category.color, "AsaCoffeeBrown")
        XCTAssertEqual(category.flashcards.count, 0)
        XCTAssertEqual(category.totalFlashcards, 0)
        XCTAssertEqual(category.studiedFlashcards, 0)
        XCTAssertEqual(category.studyProgress, 0.0)
    }
    
    func testCategoryDefaultValues() throws {
        let category = Category(name: "テストカテゴリ")
        
        XCTAssertEqual(category.icon, "folder")
        XCTAssertEqual(category.color, "AsaCoffeeBrown")
    }
    
    func testCategoryStudyProgress() throws {
        let category = Category(name: "テスト")
        let flashcard1 = Flashcard(word: "apple", meaning: "りんご", category: category)
        let flashcard2 = Flashcard(word: "book", meaning: "本", category: category)
        
        category.flashcards = [flashcard1, flashcard2]
        
        // 初期状態：学習進捗0%
        XCTAssertEqual(category.totalFlashcards, 2)
        XCTAssertEqual(category.studiedFlashcards, 0)
        XCTAssertEqual(category.studyProgress, 0.0)
        
        // 1つ目のカードを学習
        flashcard1.studyProgress.recordCorrect()
        XCTAssertEqual(category.studiedFlashcards, 1)
        XCTAssertEqual(category.studyProgress, 0.5)
        
        // 2つ目のカードを学習
        flashcard2.studyProgress.recordCorrect()
        XCTAssertEqual(category.studiedFlashcards, 2)
        XCTAssertEqual(category.studyProgress, 1.0)
    }
    
    // MARK: - Flashcard Tests
    
    func testFlashcardInitialization() throws {
        let category = Category(name: "英語")
        let flashcard = Flashcard(
            word: "hello",
            meaning: "こんにちは",
            example: "Hello, world!",
            pronunciation: "həˈloʊ",
            category: category
        )
        
        XCTAssertEqual(flashcard.word, "hello")
        XCTAssertEqual(flashcard.meaning, "こんにちは")
        XCTAssertEqual(flashcard.example, "Hello, world!")
        XCTAssertEqual(flashcard.pronunciation, "həˈloʊ")
        XCTAssertFalse(flashcard.isBookmarked)
        XCTAssertEqual(flashcard.category?.name, "英語")
        XCTAssertNotNil(flashcard.studyProgress)
    }
    
    func testFlashcardOptionalFields() throws {
        let flashcard = Flashcard(word: "test", meaning: "テスト")
        
        XCTAssertNil(flashcard.example)
        XCTAssertNil(flashcard.pronunciation)
        XCTAssertNil(flashcard.category)
    }
    
    func testFlashcardDifficultyLevel() throws {
        let flashcard = Flashcard(word: "test", meaning: "テスト")
        
        // 初期状態：正解率0% = 難しい
        XCTAssertEqual(flashcard.difficultyLevel, .hard)
        
        // 正解率50%：普通
        flashcard.studyProgress.recordCorrect()
        flashcard.studyProgress.recordIncorrect()
        XCTAssertEqual(flashcard.difficultyLevel, .medium)
        
        // 正解率80%以上：簡単
        flashcard.studyProgress.recordCorrect()
        flashcard.studyProgress.recordCorrect()
        flashcard.studyProgress.recordCorrect()
        // 現在の正解率: 4/5 = 80%
        XCTAssertEqual(flashcard.difficultyLevel, .easy)
    }
    
    // MARK: - StudyProgress Tests
    
    func testStudyProgressInitialization() throws {
        let progress = StudyProgress()
        
        XCTAssertEqual(progress.correctAnswers, 0)
        XCTAssertEqual(progress.totalAnswers, 0)
        XCTAssertNil(progress.lastStudiedAt)
        XCTAssertEqual(progress.streak, 0)
        XCTAssertFalse(progress.isStudied)
        XCTAssertNil(progress.nextReviewDate)
        XCTAssertEqual(progress.correctRate, 0.0)
        XCTAssertTrue(progress.needsReview) // 未学習なので復習が必要
    }
    
    func testStudyProgressCorrectRate() throws {
        let progress = StudyProgress()
        
        // 初期状態
        XCTAssertEqual(progress.correctRate, 0.0)
        
        // 正解1回、不正解1回
        progress.recordCorrect()
        progress.recordIncorrect()
        XCTAssertEqual(progress.correctRate, 0.5)
        
        // 正解3回、不正解1回
        progress.recordCorrect()
        progress.recordCorrect()
        XCTAssertEqual(progress.correctRate, 0.75)
    }
    
    func testStudyProgressRecordCorrect() throws {
        let progress = StudyProgress()
        let beforeDate = Date()
        
        progress.recordCorrect()
        
        XCTAssertEqual(progress.correctAnswers, 1)
        XCTAssertEqual(progress.totalAnswers, 1)
        XCTAssertEqual(progress.streak, 1)
        XCTAssertTrue(progress.isStudied)
        XCTAssertNotNil(progress.lastStudiedAt)
        XCTAssertNotNil(progress.nextReviewDate)
        
        // 時刻が適切に設定されているかチェック
        let afterDate = Date()
        XCTAssertGreaterThanOrEqual(progress.lastStudiedAt!, beforeDate)
        XCTAssertLessThanOrEqual(progress.lastStudiedAt!, afterDate)
        
        // 次回復習日が1日後に設定されているかチェック
        let expectedDate = Calendar.current.date(byAdding: .day, value: 1, to: beforeDate)!
        let actualDate = progress.nextReviewDate!
        let timeDifference = abs(actualDate.timeIntervalSince(expectedDate))
        XCTAssertLessThan(timeDifference, 2.0) // 2秒以内の誤差
    }
    
    func testStudyProgressRecordIncorrect() throws {
        let progress = StudyProgress()
        progress.recordCorrect() // streak = 1
        progress.recordCorrect() // streak = 2
        
        let beforeDate = Date()
        progress.recordIncorrect()
        
        XCTAssertEqual(progress.correctAnswers, 2)
        XCTAssertEqual(progress.totalAnswers, 3)
        XCTAssertEqual(progress.streak, 0) // streakがリセットされる
        XCTAssertTrue(progress.isStudied)
        XCTAssertNotNil(progress.lastStudiedAt)
        XCTAssertNotNil(progress.nextReviewDate)
        
        // 不正解の場合は翌日復習
        let expectedDate = Calendar.current.date(byAdding: .day, value: 1, to: beforeDate)!
        let actualDate = progress.nextReviewDate!
        let timeDifference = abs(actualDate.timeIntervalSince(expectedDate))
        XCTAssertLessThan(timeDifference, 2.0)
    }
    
    func testStudyProgressSpacedRepetitionAlgorithm() throws {
        let progress = StudyProgress()
        
        // streak 1: 1日後
        progress.recordCorrect()
        var nextReview = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertEqual(
            Calendar.current.dateComponents([.day], from: Date(), to: progress.nextReviewDate!).day,
            Calendar.current.dateComponents([.day], from: Date(), to: nextReview).day
        )
        
        // streak 2: 3日後
        progress.recordCorrect()
        nextReview = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        XCTAssertEqual(
            Calendar.current.dateComponents([.day], from: Date(), to: progress.nextReviewDate!).day,
            Calendar.current.dateComponents([.day], from: Date(), to: nextReview).day
        )
        
        // streak 3: 7日後
        progress.recordCorrect()
        nextReview = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        XCTAssertEqual(
            Calendar.current.dateComponents([.day], from: Date(), to: progress.nextReviewDate!).day,
            Calendar.current.dateComponents([.day], from: Date(), to: nextReview).day
        )
    }
    
    func testStudyProgressNeedsReview() throws {
        let progress = StudyProgress()
        
        // 未学習の場合は復習が必要
        XCTAssertTrue(progress.needsReview)
        
        // 将来の日付を設定（復習不要）
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        progress.nextReviewDate = futureDate
        XCTAssertFalse(progress.needsReview)
        
        // 過去の日付を設定（復習が必要）
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        progress.nextReviewDate = pastDate
        XCTAssertTrue(progress.needsReview)
        
        // 現在の日付（境界条件）
        progress.nextReviewDate = Date()
        XCTAssertTrue(progress.needsReview)
    }
    
    // MARK: - StudyLevel Tests
    
    func testStudyLevelColors() throws {
        XCTAssertEqual(StudyLevel.easy.color, "AsaMutedSage")
        XCTAssertEqual(StudyLevel.medium.color, "AsaCoffeeBrown")
        XCTAssertEqual(StudyLevel.hard.color, "AsaMocha")
    }
    
    func testStudyLevelRawValues() throws {
        XCTAssertEqual(StudyLevel.easy.rawValue, "簡単")
        XCTAssertEqual(StudyLevel.medium.rawValue, "普通")
        XCTAssertEqual(StudyLevel.hard.rawValue, "難しい")
    }
}