import Foundation
import SwiftData

/// 家系図データサービス - CRUD操作を提供
@MainActor
public final class FamilyTreeDataService {
    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initializer

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - FamilyTree CRUD

    /// 全ての家系図を取得
    public func fetchAllTrees() throws -> [FamilyTree] {
        let descriptor = FetchDescriptor<FamilyTree>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// IDで家系図を取得
    public func fetchTree(id: UUID) throws -> FamilyTree? {
        let descriptor = FetchDescriptor<FamilyTree>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// 家系図を作成
    @discardableResult
    public func createTree(name: String, notes: String? = nil) throws -> FamilyTree {
        let tree = FamilyTree(name: name, notes: notes)
        modelContext.insert(tree)
        try modelContext.save()
        return tree
    }

    /// 家系図を更新
    public func updateTree(_ tree: FamilyTree) throws {
        tree.updatedAt = Date()
        try modelContext.save()
    }

    /// 家系図を削除
    public func deleteTree(_ tree: FamilyTree) throws {
        modelContext.delete(tree)
        try modelContext.save()
    }

    // MARK: - FamilyMember CRUD

    /// 家系図のメンバーを取得
    public func fetchMembers(of tree: FamilyTree) -> [FamilyMember] {
        tree.members
    }

    /// IDでメンバーを取得
    public func fetchMember(id: UUID) throws -> FamilyMember? {
        let descriptor = FetchDescriptor<FamilyMember>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// メンバーを追加
    @discardableResult
    public func addMember(
        to tree: FamilyTree,
        firstName: String,
        lastName: String,
        gender: Gender = .other,
        birthDate: Date? = nil,
        deathDate: Date? = nil,
        birthPlace: String? = nil,
        notes: String? = nil,
        profileImageData: Data? = nil
    ) throws -> FamilyMember {
        let member = FamilyMember(
            firstName: firstName,
            lastName: lastName,
            gender: gender,
            birthDate: birthDate,
            deathDate: deathDate,
            birthPlace: birthPlace,
            notes: notes,
            profileImageData: profileImageData
        )

        modelContext.insert(member)
        tree.addMember(member)
        try modelContext.save()
        return member
    }

    /// メンバーを更新
    public func updateMember(_ member: FamilyMember) throws {
        member.updatedAt = Date()
        try modelContext.save()
    }

    /// メンバーを削除
    public func deleteMember(_ member: FamilyMember, from tree: FamilyTree) throws {
        tree.removeMember(member)
        modelContext.delete(member)
        try modelContext.save()
    }

    // MARK: - Relationship Management

    /// 親子関係を設定
    public func setParentChild(parent: FamilyMember, child: FamilyMember) throws {
        // 循環チェック
        guard !wouldCreateCycle(parent: parent, child: child) else {
            throw FamilyTreeError.circularRelationship
        }

        child.addParent(parent)
        try modelContext.save()
    }

    /// 親子関係を解除
    public func removeParentChild(parent: FamilyMember, child: FamilyMember) throws {
        child.removeParent(parent)
        try modelContext.save()
    }

    /// 婚姻関係を作成
    @discardableResult
    public func createMarriage(
        partner1: FamilyMember,
        partner2: FamilyMember,
        marriageDate: Date? = nil,
        marriagePlace: String? = nil
    ) throws -> Marriage {
        let marriage = Marriage(
            marriageDate: marriageDate,
            marriagePlace: marriagePlace
        )

        modelContext.insert(marriage)
        marriage.setPartners(partner1, partner2)
        try modelContext.save()
        return marriage
    }

    /// 婚姻関係を更新
    public func updateMarriage(_ marriage: Marriage) throws {
        marriage.updatedAt = Date()
        try modelContext.save()
    }

    /// 婚姻関係を削除
    public func deleteMarriage(_ marriage: Marriage) throws {
        for partner in marriage.partners {
            partner.marriages.removeAll { $0.id == marriage.id }
        }
        modelContext.delete(marriage)
        try modelContext.save()
    }

    /// 離婚を設定
    public func setDivorce(_ marriage: Marriage, divorceDate: Date) throws {
        marriage.divorceDate = divorceDate
        marriage.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Helper Methods

    /// 循環参照チェック
    private func wouldCreateCycle(parent: FamilyMember, child: FamilyMember) -> Bool {
        // 自分自身の親にはなれない
        if parent.id == child.id {
            return true
        }

        // 子孫が親になることはできない
        return isDescendant(of: child, potentialAncestor: parent)
    }

    /// メンバーが祖先の子孫かどうかを判定
    private func isDescendant(of ancestor: FamilyMember, potentialAncestor: FamilyMember) -> Bool {
        var visited = Set<UUID>()
        return isDescendantRecursive(ancestor: ancestor, current: potentialAncestor, visited: &visited)
    }

    private func isDescendantRecursive(ancestor: FamilyMember, current: FamilyMember, visited: inout Set<UUID>) -> Bool {
        if visited.contains(current.id) {
            return false
        }
        visited.insert(current.id)

        if current.id == ancestor.id {
            return true
        }

        for child in current.children {
            if isDescendantRecursive(ancestor: ancestor, current: child, visited: &visited) {
                return true
            }
        }

        return false
    }

    // MARK: - Statistics

    /// 家系図の統計情報を取得
    public func getStatistics(for tree: FamilyTree) -> TreeStatistics {
        TreeStatistics(tree: tree)
    }
}

// MARK: - TreeStatistics

/// 家系図の統計情報
public struct TreeStatistics: Sendable {
    public let totalMembers: Int
    public let aliveMembers: Int
    public let deceasedMembers: Int
    public let maleCount: Int
    public let femaleCount: Int
    public let otherGenderCount: Int
    public let generationCount: Int
    public let marriageCount: Int
    public let averageAge: Double?
    public let averageAgeOfLiving: Double?
    public let oldestAge: Int?
    public let youngestAge: Int?

    /// 年齢分布（10歳刻み）
    public let ageDistribution: [AgeRange: Int]

    /// 世代別人数
    public let generationDistribution: [Int: Int]

    public init(tree: FamilyTree) {
        self.totalMembers = tree.memberCount
        self.aliveMembers = tree.aliveMemberCount
        self.deceasedMembers = tree.deceasedMemberCount
        self.maleCount = tree.maleCount
        self.femaleCount = tree.femaleCount
        self.otherGenderCount = tree.otherGenderCount
        self.generationCount = tree.generationCount
        self.marriageCount = tree.marriageCount
        self.averageAge = tree.averageAge
        self.averageAgeOfLiving = tree.averageAgeOfLiving
        self.oldestAge = tree.oldestMember?.age
        self.youngestAge = tree.youngestMember?.age

        // 年齢分布を計算
        var distribution: [AgeRange: Int] = [:]
        for range in AgeRange.allCases {
            distribution[range] = 0
        }
        for member in tree.members {
            if let age = member.age {
                let range = AgeRange.from(age: age)
                distribution[range, default: 0] += 1
            }
        }
        self.ageDistribution = distribution

        // 世代別人数を計算
        tree.calculateGenerations()
        var genDistribution: [Int: Int] = [:]
        for member in tree.members {
            genDistribution[member.generation, default: 0] += 1
        }
        self.generationDistribution = genDistribution
    }
}

// MARK: - AgeRange

/// 年齢範囲（統計用）
public enum AgeRange: String, CaseIterable, Sendable, Comparable {
    case under10 = "0-9"
    case teens = "10-19"
    case twenties = "20-29"
    case thirties = "30-39"
    case forties = "40-49"
    case fifties = "50-59"
    case sixties = "60-69"
    case seventies = "70-79"
    case eighties = "80-89"
    case ninetyPlus = "90+"

    public var displayName: String {
        switch self {
        case .under10: return "0-9歳"
        case .teens: return "10代"
        case .twenties: return "20代"
        case .thirties: return "30代"
        case .forties: return "40代"
        case .fifties: return "50代"
        case .sixties: return "60代"
        case .seventies: return "70代"
        case .eighties: return "80代"
        case .ninetyPlus: return "90歳以上"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .under10: return 0
        case .teens: return 1
        case .twenties: return 2
        case .thirties: return 3
        case .forties: return 4
        case .fifties: return 5
        case .sixties: return 6
        case .seventies: return 7
        case .eighties: return 8
        case .ninetyPlus: return 9
        }
    }

    public static func < (lhs: AgeRange, rhs: AgeRange) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    public static func from(age: Int) -> AgeRange {
        switch age {
        case ..<10: return .under10
        case 10..<20: return .teens
        case 20..<30: return .twenties
        case 30..<40: return .thirties
        case 40..<50: return .forties
        case 50..<60: return .fifties
        case 60..<70: return .sixties
        case 70..<80: return .seventies
        case 80..<90: return .eighties
        default: return .ninetyPlus
        }
    }
}
