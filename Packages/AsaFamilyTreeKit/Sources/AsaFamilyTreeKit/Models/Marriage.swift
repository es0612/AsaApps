import Foundation
import SwiftData

/// 婚姻関係モデル - 配偶者間の関係を表す
@Model
public final class Marriage {
    // MARK: - Properties

    @Attribute(.unique) public var id: UUID
    public var marriageDate: Date?
    public var divorceDate: Date?
    public var marriagePlace: String?
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date

    // MARK: - Relationships

    @Relationship
    public var partners: [FamilyMember] = []

    // MARK: - Initializer

    public init(
        id: UUID = UUID(),
        marriageDate: Date? = nil,
        divorceDate: Date? = nil,
        marriagePlace: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.marriageDate = marriageDate
        self.divorceDate = divorceDate
        self.marriagePlace = marriagePlace
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// 離婚済みかどうか
    public var isDivorced: Bool {
        divorceDate != nil
    }

    /// 現在も婚姻中かどうか
    public var isCurrentlyMarried: Bool {
        divorceDate == nil
    }

    /// 婚姻期間（年数）
    public var marriageDuration: Int? {
        guard let marriageDate = marriageDate else { return nil }
        let endDate = divorceDate ?? Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: marriageDate, to: endDate)
        return components.year
    }

    /// 婚姻日の表示文字列
    public var marriageDateString: String? {
        guard let marriageDate = marriageDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: marriageDate)
    }

    /// 離婚日の表示文字列
    public var divorceDateString: String? {
        guard let divorceDate = divorceDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: divorceDate)
    }

    /// パートナーの名前一覧
    public var partnerNames: String {
        partners.map { $0.fullName }.joined(separator: " & ")
    }

    // MARK: - Methods

    /// パートナーを設定（常に2人）
    public func setPartners(_ partner1: FamilyMember, _ partner2: FamilyMember) {
        partners = [partner1, partner2]

        if !partner1.marriages.contains(where: { $0.id == self.id }) {
            partner1.marriages.append(self)
        }
        if !partner2.marriages.contains(where: { $0.id == self.id }) {
            partner2.marriages.append(self)
        }

        self.updatedAt = Date()
    }

    /// 指定したパートナーの配偶者を取得
    public func getSpouse(of member: FamilyMember) -> FamilyMember? {
        partners.first { $0.id != member.id }
    }

    /// 婚姻情報を更新
    public func update(
        marriageDate: Date?? = nil,
        divorceDate: Date?? = nil,
        marriagePlace: String?? = nil,
        notes: String?? = nil
    ) {
        if case .some(let date) = marriageDate {
            self.marriageDate = date
        }
        if case .some(let date) = divorceDate {
            self.divorceDate = date
        }
        if case .some(let place) = marriagePlace {
            self.marriagePlace = place
        }
        if case .some(let text) = notes {
            self.notes = text
        }
        self.updatedAt = Date()
    }
}

// MARK: - Hashable

extension Marriage: Hashable {
    public static func == (lhs: Marriage, rhs: Marriage) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
