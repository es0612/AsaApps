import Foundation
import SwiftData

/// 家系図モデル - 家族メンバーのコレクションを管理
@Model
public final class FamilyTree {
    // MARK: - Properties

    @Attribute(.unique) public var id: UUID
    public var name: String
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade)
    public var members: [FamilyMember] = []

    // MARK: - Initializer

    public init(
        id: UUID = UUID(),
        name: String,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// メンバー数
    public var memberCount: Int {
        members.count
    }

    /// 存命メンバー数
    public var aliveMemberCount: Int {
        members.filter { $0.isAlive }.count
    }

    /// 故人メンバー数
    public var deceasedMemberCount: Int {
        members.filter { !$0.isAlive }.count
    }

    /// ルートメンバー（親がいないメンバー）
    public var rootMembers: [FamilyMember] {
        members.filter { $0.parents.isEmpty }
    }

    /// 世代数
    public var generationCount: Int {
        guard !members.isEmpty else { return 0 }
        calculateGenerations()
        let maxGeneration = members.map { $0.generation }.max() ?? 0
        return maxGeneration + 1
    }

    /// 男性メンバー数
    public var maleCount: Int {
        members.filter { $0.gender == .male }.count
    }

    /// 女性メンバー数
    public var femaleCount: Int {
        members.filter { $0.gender == .female }.count
    }

    /// その他の性別メンバー数
    public var otherGenderCount: Int {
        members.filter { $0.gender == .other }.count
    }

    /// 平均年齢
    public var averageAge: Double? {
        let ages = members.compactMap { $0.age }
        guard !ages.isEmpty else { return nil }
        return Double(ages.reduce(0, +)) / Double(ages.count)
    }

    /// 存命メンバーの平均年齢
    public var averageAgeOfLiving: Double? {
        let ages = members.filter { $0.isAlive }.compactMap { $0.age }
        guard !ages.isEmpty else { return nil }
        return Double(ages.reduce(0, +)) / Double(ages.count)
    }

    /// 最年長メンバー
    public var oldestMember: FamilyMember? {
        members.filter { $0.age != nil }.max { ($0.age ?? 0) < ($1.age ?? 0) }
    }

    /// 最年少メンバー
    public var youngestMember: FamilyMember? {
        members.filter { $0.age != nil }.min { ($0.age ?? 0) < ($1.age ?? 0) }
    }

    /// 婚姻関係の数
    public var marriageCount: Int {
        let allMarriages = Set(members.flatMap { $0.marriages })
        return allMarriages.count
    }

    // MARK: - Methods

    /// メンバーを追加
    public func addMember(_ member: FamilyMember) {
        guard !members.contains(where: { $0.id == member.id }) else { return }
        members.append(member)
        member.familyTree = self
        self.updatedAt = Date()
    }

    /// メンバーを削除
    public func removeMember(_ member: FamilyMember) {
        // 関係を先に解除
        for parent in member.parents {
            parent.children.removeAll { $0.id == member.id }
        }
        for child in member.children {
            child.parents.removeAll { $0.id == member.id }
        }
        for marriage in member.marriages {
            marriage.partners.removeAll { $0.id == member.id }
        }

        members.removeAll { $0.id == member.id }
        self.updatedAt = Date()
    }

    /// 家系図情報を更新
    public func update(
        name: String? = nil,
        notes: String?? = nil
    ) {
        if let name = name {
            self.name = name
        }
        if case .some(let text) = notes {
            self.notes = text
        }
        self.updatedAt = Date()
    }

    /// 世代を計算（ルートメンバーを世代0として）
    public func calculateGenerations() {
        // まず全員の世代をリセット
        for member in members {
            member.generation = -1
        }

        // ルートメンバーを世代0に設定
        for root in rootMembers {
            root.generation = 0
            propagateGeneration(from: root)
        }

        // 世代が設定されていないメンバーがあれば0に設定
        for member in members where member.generation == -1 {
            member.generation = 0
        }
    }

    /// 世代を子孫に伝播
    private func propagateGeneration(from member: FamilyMember) {
        for child in member.children {
            let newGeneration = member.generation + 1
            if child.generation < newGeneration {
                child.generation = newGeneration
                propagateGeneration(from: child)
            }
        }
    }

    /// 世代別にメンバーをグループ化
    public func membersByGeneration() -> [Int: [FamilyMember]] {
        calculateGenerations()
        var result: [Int: [FamilyMember]] = [:]
        for member in members {
            result[member.generation, default: []].append(member)
        }
        return result
    }

    /// 名前でメンバーを検索
    public func searchMembers(query: String) -> [FamilyMember] {
        guard !query.isEmpty else { return members }
        let lowercasedQuery = query.lowercased()
        return members.filter { member in
            member.fullName.lowercased().contains(lowercasedQuery) ||
            member.firstName.lowercased().contains(lowercasedQuery) ||
            member.lastName.lowercased().contains(lowercasedQuery)
        }
    }
}

// MARK: - Hashable

extension FamilyTree: Hashable {
    public static func == (lhs: FamilyTree, rhs: FamilyTree) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
