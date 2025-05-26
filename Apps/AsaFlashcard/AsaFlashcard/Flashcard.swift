import Foundation

struct Flashcard: Identifiable {
    let id = UUID()
    let word: String
    let meaning: String
}
