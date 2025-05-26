import SwiftUI

class FlashcardManager: ObservableObject {
    @Published var flashcards: [Flashcard] = [
        Flashcard(word: "Apple", meaning: "りんご"),
        Flashcard(word: "Book", meaning: "本"),
        Flashcard(word: "Cat", meaning: "猫"),
        Flashcard(word: "Dog", meaning: "犬"),
        Flashcard(word: "Sun", meaning: "太陽")
    ]
    @Published var currentIndex: Int = 0

    var currentCard: Flashcard {
        flashcards[currentIndex]
    }

    func nextCard() {
        if currentIndex < flashcards.count - 1 {
            currentIndex += 1
        }
    }

    func previousCard() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
}
