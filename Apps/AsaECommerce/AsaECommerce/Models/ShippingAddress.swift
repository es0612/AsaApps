import Foundation

struct ShippingAddress: Identifiable, Codable, Sendable {
    let id: UUID
    var fullName: String
    var postalCode: String
    var prefecture: String
    var city: String
    var addressLine1: String
    var addressLine2: String?
    var phoneNumber: String
    var isDefault: Bool

    // MARK: - Formatted Address

    var formattedAddress: String {
        var parts = ["〒\(postalCode)", prefecture, city, addressLine1]
        if let line2 = addressLine2, !line2.isEmpty {
            parts.append(line2)
        }
        return parts.joined()
    }

    // MARK: - Default

    init(
        id: UUID = UUID(),
        fullName: String = "",
        postalCode: String = "",
        prefecture: String = "",
        city: String = "",
        addressLine1: String = "",
        addressLine2: String? = nil,
        phoneNumber: String = "",
        isDefault: Bool = false
    ) {
        self.id = id
        self.fullName = fullName
        self.postalCode = postalCode
        self.prefecture = prefecture
        self.city = city
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2
        self.phoneNumber = phoneNumber
        self.isDefault = isDefault
    }

    // MARK: - Prefectures

    static let prefectures: [String] = [
        "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県",
        "茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県",
        "新潟県", "富山県", "石川県", "福井県", "山梨県", "長野県",
        "岐阜県", "静岡県", "愛知県", "三重県",
        "滋賀県", "京都府", "大阪府", "兵庫県", "奈良県", "和歌山県",
        "鳥取県", "島根県", "岡山県", "広島県", "山口県",
        "徳島県", "香川県", "愛媛県", "高知県",
        "福岡県", "佐賀県", "長崎県", "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県"
    ]
}
