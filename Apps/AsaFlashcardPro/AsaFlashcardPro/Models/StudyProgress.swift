import Foundation
import SwiftData

@Model
class StudyProgress {
    @Attribute(.unique) var id: UUID
    var correctAnswers: Int
    var totalAnswers: Int
    var lastStudiedAt: Date?
    var streak: Int  // 連続正解回数
    var isStudied: Bool
    var nextReviewDate: Date?
    
    init() {
        self.id = UUID()
        self.correctAnswers = 0
        self.totalAnswers = 0
        self.lastStudiedAt = nil
        self.streak = 0
        self.isStudied = false
        self.nextReviewDate = nil
    }
    
    // 正解率
    var correctRate: Double {
        guard totalAnswers > 0 else { return 0.0 }
        return Double(correctAnswers) / Double(totalAnswers)
    }
    
    // 正解を記録
    func recordCorrect() {
        correctAnswers += 1
        totalAnswers += 1
        streak += 1
        lastStudiedAt = Date()
        isStudied = true
        
        // スパースレプティション（間隔反復）アルゴリズムの簡易実装
        let interval = calculateInterval()
        nextReviewDate = Calendar.current.date(byAdding: .day, value: interval, to: Date())
    }
    
    // 不正解を記録
    func recordIncorrect() {
        totalAnswers += 1
        streak = 0
        lastStudiedAt = Date()
        isStudied = true
        
        // 間違えた場合は翌日に復習
        nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
    }
    
    // 復習間隔の計算
    private func calculateInterval() -> Int {
        switch streak {
        case 1:
            return 1  // 1日後
        case 2:
            return 3  // 3日後
        case 3:
            return 7  // 1週間後
        case 4:
            return 14 // 2週間後
        case 5:
            return 30 // 1ヶ月後
        default:
            return min(90, streak * 15) // 最大3ヶ月まで
        }
    }
    
    // 復習が必要かどうか
    var needsReview: Bool {
        guard let nextReviewDate = nextReviewDate else { return !isStudied }
        return Date() >= nextReviewDate
    }
}