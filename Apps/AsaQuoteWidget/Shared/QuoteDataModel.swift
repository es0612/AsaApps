import Foundation

// MARK: - Quote Category
enum QuoteCategory: String, CaseIterable, Codable {
    case encouragement = "励まし"
    case success = "成功"
    case family = "家族"
    case morningActivity = "朝活"
    case work = "仕事"
    case personal = "自己成長"
    
    var displayName: String {
        return self.rawValue
    }
    
    var emoji: String {
        switch self {
        case .encouragement: return "💪"
        case .success: return "🎯"
        case .family: return "👨‍👩‍👧‍👦"
        case .morningActivity: return "🌅"
        case .work: return "💼"
        case .personal: return "📈"
        }
    }
}

// MARK: - Quote Model
struct Quote: Codable, Identifiable, Hashable {
    let id: UUID
    let text: String
    let author: String
    let category: QuoteCategory
    
    init(text: String, author: String, category: QuoteCategory) {
        self.id = UUID()
        self.text = text
        self.author = author
        self.category = category
    }
}

// MARK: - Quote Data Provider
class QuoteDataProvider {
    static let shared = QuoteDataProvider()
    
    private init() {}
    
    // MARK: - Sample Quotes
    lazy var sampleQuotes: [Quote] = [
        // 励まし
        Quote(text: "今日という日は、残りの人生の最初の日である", author: "アビー・ホフマン", category: .encouragement),
        Quote(text: "困難こそが人を育てる", author: "松下幸之助", category: .encouragement),
        Quote(text: "失敗は成功の母である", author: "トーマス・エジソン", category: .encouragement),
        Quote(text: "努力すれば報われる。報われなかったら、それはまだ努力が足りない", author: "王貞治", category: .encouragement),
        
        // 成功
        Quote(text: "成功とは、準備と機会が出会うところに生まれる", author: "ボビー・ナイト", category: .success),
        Quote(text: "夢を見ることができれば、それは実現できる", author: "ウォルト・ディズニー", category: .success),
        Quote(text: "成功への道に近道はない", author: "ベンジャミン・フランクリン", category: .success),
        Quote(text: "天才とは1％のインスピレーションと99％のパースピレーション（努力）である", author: "トーマス・エジソン", category: .success),
        
        // 家族
        Quote(text: "家族は人生で最も大切な宝物である", author: "不明", category: .family),
        Quote(text: "子どもは親の背中を見て育つ", author: "日本のことわざ", category: .family),
        Quote(text: "家族の愛は人生の最大の祝福である", author: "不明", category: .family),
        Quote(text: "親として最高の贈り物は、子どもに時間を与えることである", author: "不明", category: .family),
        
        // 朝活
        Quote(text: "早起きは三文の徳", author: "日本のことわざ", category: .morningActivity),
        Quote(text: "朝の時間は金に等しい", author: "ベンジャミン・フランクリン", category: .morningActivity),
        Quote(text: "早朝の静寂な時間こそ、最も創造的な時間である", author: "不明", category: .morningActivity),
        Quote(text: "朝活で人生が変わる。まず自分が変われ", author: "不明", category: .morningActivity),
        
        // 仕事
        Quote(text: "仕事に愛情を持てば、人生が楽しくなる", author: "不明", category: .work),
        Quote(text: "チームワークがあれば、普通の人が非凡な結果を出せる", author: "アンドリュー・カーネギー", category: .work),
        Quote(text: "良いリーダーは人を育てる。偉大なリーダーは、リーダーを育てる", author: "不明", category: .work),
        
        // 自己成長
        Quote(text: "昨日の自分を超えることが、真の勝利である", author: "不明", category: .personal),
        Quote(text: "学ぶことをやめた者は老いる。学び続ける者は若さを保つ", author: "ヘンリー・フォード", category: .personal),
        Quote(text: "変化こそ人生において唯一確実なものである", author: "不明", category: .personal),
        Quote(text: "読書は精神の食事である", author: "不明", category: .personal)
    ]
    
    // MARK: - Quote Management Methods
    func getAllQuotes() -> [Quote] {
        return sampleQuotes
    }
    
    func getQuotes(for category: QuoteCategory) -> [Quote] {
        return sampleQuotes.filter { $0.category == category }
    }
    
    func getRandomQuote() -> Quote {
        return sampleQuotes.randomElement() ?? sampleQuotes.first!
    }
    
    func getRandomQuote(from category: QuoteCategory) -> Quote {
        let categoryQuotes = getQuotes(for: category)
        return categoryQuotes.randomElement() ?? sampleQuotes.first!
    }
    
    func searchQuotes(with keyword: String) -> [Quote] {
        guard !keyword.isEmpty else { return sampleQuotes }
        
        return sampleQuotes.filter { quote in
            quote.text.localizedCaseInsensitiveContains(keyword) ||
            quote.author.localizedCaseInsensitiveContains(keyword)
        }
    }
}