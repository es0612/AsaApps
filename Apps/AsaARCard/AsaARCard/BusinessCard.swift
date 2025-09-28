import Foundation

// MARK: - 名刺データモデル
struct BusinessCard: Codable, Identifiable {
    var id = UUID()
    var name: String
    var title: String
    var company: String
    var email: String
    var phone: String
    var website: String

    init(name: String = "", title: String = "", company: String = "", email: String = "", phone: String = "", website: String = "") {
        self.id = UUID()
        self.name = name
        self.title = title
        self.company = company
        self.email = email
        self.phone = phone
        self.website = website
    }

    enum CodingKeys: String, CodingKey {
        case name, title, company, email, phone, website
    }
    
    // 空のフィールドをチェック
    var isEmpty: Bool {
        return name.isEmpty && title.isEmpty && company.isEmpty && email.isEmpty && phone.isEmpty && website.isEmpty
    }
    
    // デフォルト名刺データ
    static var sample: BusinessCard {
        return BusinessCard(
            name: "朝活パパ",
            title: "iOS Developer",
            company: "AsaApps",
            email: "contact@asaapps.dev",
            phone: "090-xxxx-xxxx",
            website: "https://asaapps.dev"
        )
    }
}

// MARK: - UserDefaults Extensions
extension BusinessCard {
    private static let userDefaultsKey = "AsaARCard_BusinessCard"
    
    // UserDefaultsからの読み込み
    static func loadFromUserDefaults() -> BusinessCard {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let card = try? JSONDecoder().decode(BusinessCard.self, from: data) else {
            return BusinessCard.sample
        }
        return card
    }
    
    // UserDefaultsへの保存
    func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
}