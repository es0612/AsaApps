import Testing
import Foundation
@testable import AsaARCard

struct BusinessCardTests {
    
    @Test("BusinessCardの初期化テスト")
    func businessCardInitialization() throws {
        let name = "朝活パパ"
        let title = "iOS Developer"
        let company = "AsaApps"
        let email = "contact@asaapps.dev"
        let phone = "090-xxxx-xxxx"
        let website = "https://asaapps.dev"
        
        let card = BusinessCard(
            name: name,
            title: title,
            company: company,
            email: email,
            phone: phone,
            website: website
        )
        
        #expect(card.name == name)
        #expect(card.title == title)
        #expect(card.company == company)
        #expect(card.email == email)
        #expect(card.phone == phone)
        #expect(card.website == website)
        #expect(card.id != UUID())
    }
    
    @Test("BusinessCardのデフォルト初期化テスト")
    func businessCardDefaultInitialization() throws {
        let card = BusinessCard()
        
        #expect(card.name.isEmpty)
        #expect(card.title.isEmpty)
        #expect(card.company.isEmpty)
        #expect(card.email.isEmpty)
        #expect(card.phone.isEmpty)
        #expect(card.website.isEmpty)
        #expect(card.isEmpty == true)
    }
    
    @Test("BusinessCard空チェックテスト")
    func businessCardEmptyCheck() throws {
        // 全て空の名刺
        let emptyCard = BusinessCard()
        #expect(emptyCard.isEmpty == true)
        
        // 名前のみ設定
        let nameOnlyCard = BusinessCard(name: "テスト")
        #expect(nameOnlyCard.isEmpty == false)
        
        // 完全に入力された名刺
        let fullCard = BusinessCard(
            name: "朝活パパ",
            title: "Developer",
            company: "AsaApps",
            email: "test@example.com",
            phone: "090-0000-0000",
            website: "https://example.com"
        )
        #expect(fullCard.isEmpty == false)
    }
    
    @Test("BusinessCardサンプルデータテスト")
    func businessCardSampleData() throws {
        let sample = BusinessCard.sample
        
        #expect(sample.name == "朝活パパ")
        #expect(sample.title == "iOS Developer")
        #expect(sample.company == "AsaApps")
        #expect(sample.email == "contact@asaapps.dev")
        #expect(sample.phone == "090-xxxx-xxxx")
        #expect(sample.website == "https://asaapps.dev")
        #expect(sample.isEmpty == false)
    }
    
    @Test("BusinessCard Codable準拠テスト")
    func businessCardCodable() throws {
        let originalCard = BusinessCard(
            name: "テストユーザー",
            title: "テストエンジニア",
            company: "テスト会社",
            email: "test@test.com",
            phone: "000-0000-0000",
            website: "https://test.com"
        )
        
        // エンコード
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalCard)
        #expect(data.count > 0)
        
        // デコード
        let decoder = JSONDecoder()
        let decodedCard = try decoder.decode(BusinessCard.self, from: data)
        
        #expect(decodedCard.name == originalCard.name)
        #expect(decodedCard.title == originalCard.title)
        #expect(decodedCard.company == originalCard.company)
        #expect(decodedCard.email == originalCard.email)
        #expect(decodedCard.phone == originalCard.phone)
        #expect(decodedCard.website == originalCard.website)
        // IDは異なる（UUIDのため）
        #expect(decodedCard.id != originalCard.id)
    }
}