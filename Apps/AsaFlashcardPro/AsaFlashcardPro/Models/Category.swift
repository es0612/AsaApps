import Foundation
import SwiftData

@Model
class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var color: String
    var createdAt: Date
    var flashcards: [Flashcard]
    
    init(name: String, icon: String = "folder", color: String = "AsaCoffeeBrown") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.createdAt = Date()
        self.flashcards = []
    }
    
    // 学習統計用プロパティ
    var totalFlashcards: Int {
        flashcards.count
    }
    
    var studiedFlashcards: Int {
        flashcards.filter { $0.studyProgress.isStudied }.count
    }
    
    var studyProgress: Double {
        guard totalFlashcards > 0 else { return 0.0 }
        return Double(studiedFlashcards) / Double(totalFlashcards)
    }
}