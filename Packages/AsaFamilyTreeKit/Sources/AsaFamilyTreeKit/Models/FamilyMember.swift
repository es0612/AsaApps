import Foundation
import SwiftData

/// 家族メンバーモデル - 家系図の各個人を表す
@Model
public final class FamilyMember {
    // MARK: - Properties

    @Attribute(.unique) public var id: UUID
    public var firstName: String
    public var lastName: String
    public var genderRawValue: String
    public var birthDate: Date?
    public var deathDate: Date?
    public var birthPlace: String?
    public var notes: String?
    public var profileImageData: Data?
    public var createdAt: Date
    public var updatedAt: Date

    // MARK: - Relationships

    @Relationship(inverse: \FamilyMember.children)
    public var parents: [FamilyMember] = []

    @Relationship
    public var children: [FamilyMember] = []

    @Relationship(inverse: \Marriage.partners)
    public var marriages: [Marriage] = []

    @Relationship(inverse: \FamilyTree.members)
    public var familyTree: FamilyTree?

    // MARK: - Initializer

    public init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        gender: Gender = .other,
        birthDate: Date? = nil,
        deathDate: Date? = nil,
        birthPlace: String? = nil,
        notes: String? = nil,
        profileImageData: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.genderRawValue = gender.rawValue
        self.birthDate = birthDate
        self.deathDate = deathDate
        self.birthPlace = birthPlace
        self.notes = notes
        self.profileImageData = profileImageData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// 性別（enum）
    public var gender: Gender {
        get { Gender(rawValue: genderRawValue) ?? .other }
        set { genderRawValue = newValue.rawValue }
    }

    /// フルネーム
    public var fullName: String {
        "\(lastName) \(firstName)"
    }

    /// 年齢（存命の場合は現在の年齢、故人の場合は享年）
    public var age: Int? {
        guard let birthDate = birthDate else { return nil }
        let endDate = deathDate ?? Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: birthDate, to: endDate)
        return components.year
    }

    /// 存命かどうか
    public var isAlive: Bool {
        deathDate == nil
    }

    /// 世代（ルートからの深さ、計算は外部で行う）
    @Transient
    public var generation: Int = 0

    /// 配偶者一覧
    public var spouses: [FamilyMember] {
        marriages.flatMap { marriage in
            marriage.partners.filter { $0.id != self.id }
        }
    }

    /// 現在の配偶者（離婚していない）
    public var currentSpouse: FamilyMember? {
        marriages
            .filter { $0.divorceDate == nil }
            .flatMap { $0.partners }
            .first { $0.id != self.id }
    }

    /// 兄弟姉妹
    public var siblings: [FamilyMember] {
        let siblingSet = Set(parents.flatMap { $0.children })
        return Array(siblingSet).filter { $0.id != self.id }
    }

    /// プロフィール画像があるかどうか
    public var hasProfileImage: Bool {
        profileImageData != nil
    }

    /// 生年月日の表示文字列
    public var birthDateString: String? {
        guard let birthDate = birthDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: birthDate)
    }

    /// 没年月日の表示文字列
    public var deathDateString: String? {
        guard let deathDate = deathDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: deathDate)
    }

    /// 生没年の表示文字列
    public var lifeSpanString: String {
        let birthYear = birthDate.map { Calendar.current.component(.year, from: $0) }
        let deathYear = deathDate.map { Calendar.current.component(.year, from: $0) }

        switch (birthYear, deathYear) {
        case let (.some(birth), .some(death)):
            return "\(birth) - \(death)"
        case let (.some(birth), .none):
            return "\(birth) -"
        case let (.none, .some(death)):
            return "- \(death)"
        case (.none, .none):
            return ""
        }
    }

    // MARK: - Methods

    /// メンバー情報を更新
    public func update(
        firstName: String? = nil,
        lastName: String? = nil,
        gender: Gender? = nil,
        birthDate: Date?? = nil,
        deathDate: Date?? = nil,
        birthPlace: String?? = nil,
        notes: String?? = nil,
        profileImageData: Data?? = nil
    ) {
        if let firstName = firstName {
            self.firstName = firstName
        }
        if let lastName = lastName {
            self.lastName = lastName
        }
        if let gender = gender {
            self.gender = gender
        }
        if case .some(let date) = birthDate {
            self.birthDate = date
        }
        if case .some(let date) = deathDate {
            self.deathDate = date
        }
        if case .some(let place) = birthPlace {
            self.birthPlace = place
        }
        if case .some(let text) = notes {
            self.notes = text
        }
        if case .some(let data) = profileImageData {
            self.profileImageData = data
        }
        self.updatedAt = Date()
    }

    /// 親を追加
    public func addParent(_ parent: FamilyMember) {
        guard !parents.contains(where: { $0.id == parent.id }) else { return }
        parents.append(parent)
        if !parent.children.contains(where: { $0.id == self.id }) {
            parent.children.append(self)
        }
        self.updatedAt = Date()
    }

    /// 親を削除
    public func removeParent(_ parent: FamilyMember) {
        parents.removeAll { $0.id == parent.id }
        parent.children.removeAll { $0.id == self.id }
        self.updatedAt = Date()
    }

    /// 子を追加
    public func addChild(_ child: FamilyMember) {
        guard !children.contains(where: { $0.id == child.id }) else { return }
        children.append(child)
        if !child.parents.contains(where: { $0.id == self.id }) {
            child.parents.append(self)
        }
        self.updatedAt = Date()
    }

    /// 子を削除
    public func removeChild(_ child: FamilyMember) {
        children.removeAll { $0.id == child.id }
        child.parents.removeAll { $0.id == self.id }
        self.updatedAt = Date()
    }
}

// MARK: - Hashable

extension FamilyMember: Hashable {
    public static func == (lhs: FamilyMember, rhs: FamilyMember) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
