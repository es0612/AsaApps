import Foundation
import SwiftData

@Model
class Flashcard {
    @Attribute(.unique) var id: UUID
    var word: String
    var meaning: String
    var example: String?
    var pronunciation: String?
    var isBookmarked: Bool
    var createdAt: Date
    var category: Category?
    var studyProgress: StudyProgress
    
    init(word: String, meaning: String, example: String? = nil, pronunciation: String? = nil, category: Category? = nil) {
        self.id = UUID()
        self.word = word
        self.meaning = meaning
        self.example = example
        self.pronunciation = pronunciation
        self.isBookmarked = false
        self.createdAt = Date()
        self.category = category
        self.studyProgress = StudyProgress()
    }
    
    // 学習レベルの判定
    var difficultyLevel: StudyLevel {
        let correctRate = studyProgress.correctRate
        if correctRate >= 0.8 {
            return .easy
        } else if correctRate >= 0.5 {
            return .medium
        } else {
            return .hard
        }
    }
}

enum StudyLevel: String, CaseIterable {
    case easy = "簡単"
    case medium = "普通"
    case hard = "難しい"
    
    var color: String {
        switch self {
        case .easy:
            return "AsaMutedSage"
        case .medium:
            return "AsaCoffeeBrown"
        case .hard:
            return "AsaMocha"
        }
    }
}