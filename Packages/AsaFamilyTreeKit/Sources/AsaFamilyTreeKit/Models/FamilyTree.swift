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

        // 配偶者の世代を揃える（親が未登録の配偶者がルート扱いになる問題を解消）
        alignSpouseGenerations()
    }

    /// 配偶者同士の世代差を解消（配偶者がいるなら、高い方の世代に揃える）
    ///
    /// 例：鈴木健太（親登録なし → generation 0）と鈴木幸子（山田家 generation 1）の
    /// 結婚ペアは世代が一致していないと家系図の横軸が揃わない。
    private func alignSpouseGenerations() {
        var changed = true
        var iterations = 0
        let maxIterations = members.count * 2  // 無限ループ防止

        while changed && iterations < maxIterations {
            changed = false
            iterations += 1

            for member in members {
                for spouse in member.spouses {
                    if member.generation > spouse.generation {
                        spouse.generation = member.generation
                        // 子孫にも伝播（子がいればその世代も見直す）
                        propagateGeneration(from: spouse)
                        changed = true
                    }
                }
            }
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

    /// 指定したメンバーの直系血族の ID 集合を返す
    ///
    /// 含まれるメンバー：
    /// - 本人
    /// - 全ての祖先（親・祖父母・…）
    /// - 全ての子孫（子・孫・…）
    /// - 現在の配偶者（離別者は含まない）
    ///
    /// 兄弟姉妹・義親族・いとこ等は含まない。選択ハイライト用途に使う。
    public func directBloodline(of member: FamilyMember) -> Set<UUID> {
        var result: Set<UUID> = [member.id]

        // 祖先を BFS で辿る
        var ancestorQueue: [FamilyMember] = member.parents
        while let current = ancestorQueue.first {
            ancestorQueue.removeFirst()
            guard !result.contains(current.id) else { continue }
            result.insert(current.id)
            ancestorQueue.append(contentsOf: current.parents)
        }

        // 子孫を BFS で辿る
        var descendantQueue: [FamilyMember] = member.children
        while let current = descendantQueue.first {
            descendantQueue.removeFirst()
            guard !result.contains(current.id) else { continue }
            result.insert(current.id)
            descendantQueue.append(contentsOf: current.children)
        }

        // 現配偶者
        if let spouse = member.currentSpouse {
            result.insert(spouse.id)
        }

        return result
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
