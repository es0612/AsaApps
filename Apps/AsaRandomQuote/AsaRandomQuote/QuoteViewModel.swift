import Observation
import Foundation

@Observable
class QuoteViewModel {
    var currentQuote: Quote = Quote(text: "今日も一歩前へ！", isFavorite: false, timestamp: Date())
    var favoriteQuotes: [Quote] = []
    private let quotes = [
        "今日も一歩前へ！",
        "失敗は成功の第一歩",
        "笑顔でいこう！",
        "自分を信じろ！",
        "小さな行動が大きな変化に"
    ]
    
    func getRandomQuote() {
        guard let newQuoteText = quotes.randomElement(), newQuoteText != currentQuote.text else {
            getRandomQuote()
            return
        }
        currentQuote = Quote(text: newQuoteText, isFavorite: false, timestamp: Date())
    }
    
    func toggleFavorite() {
        currentQuote.isFavorite.toggle()
        if currentQuote.isFavorite {
            favoriteQuotes.append(currentQuote)
        } else {
            favoriteQuotes.removeAll { $0.id == currentQuote.id }
        }
        saveToUserDefaults()
    }
    
    func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(favoriteQuotes) {
            UserDefaults.standard.set(data, forKey: "favoriteQuotes")
        }
    }
    
    func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "favoriteQuotes"),
           let savedQuotes = try? JSONDecoder().decode([Quote].self, from: data) {
            favoriteQuotes = savedQuotes
        }
    }
    
    func deleteFavoriteQuote(_ quote: Quote) {
        favoriteQuotes.removeAll { $0.id == quote.id }
        if currentQuote.id == quote.id {
            currentQuote.isFavorite = false
        }
        saveToUserDefaults()
    }
}
