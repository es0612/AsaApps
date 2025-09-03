import Foundation

// MARK: - Shared Defaults Manager
class SharedDefaults {
    static let shared = SharedDefaults()
    
    private let appGroupID = "group.com.asaapps.AsaQuoteWidget"
    private lazy var userDefaults: UserDefaults = {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            fatalError("App Groupsが正しく設定されていません: \(appGroupID)")
        }
        return defaults
    }()
    
    private init() {}
    
    // MARK: - Keys
    private enum Keys {
        static let selectedCategory = "selectedCategory"
        static let favoriteQuotes = "favoriteQuotes"
        static let lastDisplayedQuote = "lastDisplayedQuote"
        static let updateFrequency = "updateFrequency"
        static let isRandomMode = "isRandomMode"
        static let lastUpdateTime = "lastUpdateTime"
    }
    
    // MARK: - Update Frequency Options
    enum UpdateFrequency: String, CaseIterable, Codable {
        case fifteenMinutes = "15分毎"
        case thirtyMinutes = "30分毎"
        case oneHour = "1時間毎"
        case twoHours = "2時間毎"
        case fourHours = "4時間毎"
        case daily = "1日毎"
        
        var timeInterval: TimeInterval {
            switch self {
            case .fifteenMinutes: return 15 * 60
            case .thirtyMinutes: return 30 * 60
            case .oneHour: return 60 * 60
            case .twoHours: return 2 * 60 * 60
            case .fourHours: return 4 * 60 * 60
            case .daily: return 24 * 60 * 60
            }
        }
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    // MARK: - Selected Category
    var selectedCategory: QuoteCategory {
        get {
            guard let rawValue = userDefaults.string(forKey: Keys.selectedCategory),
                  let category = QuoteCategory(rawValue: rawValue) else {
                return .encouragement // デフォルト値
            }
            return category
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.selectedCategory)
        }
    }
    
    // MARK: - Favorite Quotes
    var favoriteQuotes: [Quote] {
        get {
            guard let data = userDefaults.data(forKey: Keys.favoriteQuotes) else {
                return []
            }
            do {
                let quotes = try JSONDecoder().decode([Quote].self, from: data)
                return quotes
            } catch {
                print("お気に入り名言の読み込みに失敗: \(error)")
                return []
            }
        }
        set {
            do {
                let data = try JSONEncoder().encode(newValue)
                userDefaults.set(data, forKey: Keys.favoriteQuotes)
            } catch {
                print("お気に入り名言の保存に失敗: \(error)")
            }
        }
    }
    
    // MARK: - Last Displayed Quote
    var lastDisplayedQuote: Quote? {
        get {
            guard let data = userDefaults.data(forKey: Keys.lastDisplayedQuote) else {
                return nil
            }
            do {
                let quote = try JSONDecoder().decode(Quote.self, from: data)
                return quote
            } catch {
                print("最後に表示した名言の読み込みに失敗: \(error)")
                return nil
            }
        }
        set {
            if let quote = newValue {
                do {
                    let data = try JSONEncoder().encode(quote)
                    userDefaults.set(data, forKey: Keys.lastDisplayedQuote)
                } catch {
                    print("最後に表示した名言の保存に失敗: \(error)")
                }
            } else {
                userDefaults.removeObject(forKey: Keys.lastDisplayedQuote)
            }
        }
    }
    
    // MARK: - Update Frequency
    var updateFrequency: UpdateFrequency {
        get {
            guard let rawValue = userDefaults.string(forKey: Keys.updateFrequency),
                  let frequency = UpdateFrequency(rawValue: rawValue) else {
                return .oneHour // デフォルト値
            }
            return frequency
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.updateFrequency)
        }
    }
    
    // MARK: - Random Mode
    var isRandomMode: Bool {
        get {
            return userDefaults.bool(forKey: Keys.isRandomMode)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.isRandomMode)
        }
    }
    
    // MARK: - Last Update Time
    var lastUpdateTime: Date? {
        get {
            return userDefaults.object(forKey: Keys.lastUpdateTime) as? Date
        }
        set {
            userDefaults.set(newValue, forKey: Keys.lastUpdateTime)
        }
    }
    
    // MARK: - Favorite Management Methods
    func addFavorite(_ quote: Quote) {
        var favorites = favoriteQuotes
        if !favorites.contains(where: { $0.id == quote.id }) {
            favorites.append(quote)
            favoriteQuotes = favorites
        }
    }
    
    func removeFavorite(_ quote: Quote) {
        var favorites = favoriteQuotes
        favorites.removeAll { $0.id == quote.id }
        favoriteQuotes = favorites
    }
    
    func isFavorite(_ quote: Quote) -> Bool {
        return favoriteQuotes.contains { $0.id == quote.id }
    }
    
    // MARK: - Update Time Management
    func shouldUpdate() -> Bool {
        guard let lastUpdate = lastUpdateTime else {
            return true // 初回は更新
        }
        
        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
        return timeSinceLastUpdate >= updateFrequency.timeInterval
    }
    
    func markAsUpdated() {
        lastUpdateTime = Date()
    }
    
    // MARK: - Quote Selection Logic
    func getQuoteForWidget() -> Quote {
        let dataProvider = QuoteDataProvider.shared
        
        if isRandomMode {
            // ランダムモードの場合
            let randomQuote = dataProvider.getRandomQuote()
            lastDisplayedQuote = randomQuote
            return randomQuote
        } else {
            // 選択されたカテゴリから取得
            let categoryQuote = dataProvider.getRandomQuote(from: selectedCategory)
            lastDisplayedQuote = categoryQuote
            return categoryQuote
        }
    }
    
    // MARK: - Reset Methods
    func resetToDefaults() {
        selectedCategory = .encouragement
        favoriteQuotes = []
        lastDisplayedQuote = nil
        updateFrequency = .oneHour
        isRandomMode = false
        lastUpdateTime = nil
    }
}