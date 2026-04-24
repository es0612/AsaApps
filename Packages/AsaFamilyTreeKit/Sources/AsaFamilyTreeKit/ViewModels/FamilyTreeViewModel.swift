import Foundation
import SwiftUI
import SwiftData

/// アプリの状態
public enum AppState: Sendable, Equatable {
    case loading
    case loaded
    case error(String)
    case empty
}

/// 家系図ViewModel - メインの状態管理
@MainActor
@Observable
public final class FamilyTreeViewModel {
    // MARK: - Dependencies

    private var dataService: FamilyTreeDataService?

    // MARK: - State

    public private(set) var appState: AppState = .loading
    public private(set) var familyTrees: [FamilyTree] = []
    public private(set) var currentTree: FamilyTree?
    public private(set) var selectedMember: FamilyMember?
    /// 選択中メンバーの直系血族 ID 集合（nil の場合は全員通常表示）
    public private(set) var highlightedIDs: Set<UUID>?
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?

    // MARK: - Tree View State

    public var zoomScale: CGFloat = 0.55
    public var panOffset: CGSize = .zero
    public var searchQuery: String = ""

    // MARK: - Filter State

    public var showOnlyAlive: Bool = false
    public var selectedGeneration: Int?

    // MARK: - Computed Properties

    /// 現在の家系図のメンバー一覧
    public var members: [FamilyMember] {
        currentTree?.members ?? []
    }

    /// フィルタリングされたメンバー一覧
    public var filteredMembers: [FamilyMember] {
        var result = members

        // 検索フィルタ
        if !searchQuery.isEmpty {
            result = result.filter { member in
                member.fullName.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        // 存命フィルタ
        if showOnlyAlive {
            result = result.filter { $0.isAlive }
        }

        // 世代フィルタ
        if let generation = selectedGeneration {
            currentTree?.calculateGenerations()
            result = result.filter { $0.generation == generation }
        }

        return result
    }

    /// 統計情報
    public var statistics: TreeStatistics? {
        guard let tree = currentTree else { return nil }
        return TreeStatistics(tree: tree)
    }

    /// 世代一覧
    public var generations: [Int] {
        guard let tree = currentTree else { return [] }
        tree.calculateGenerations()
        return Array(Set(tree.members.map { $0.generation })).sorted()
    }

    /// データが空かどうか
    public var isEmpty: Bool {
        familyTrees.isEmpty
    }

    /// 現在の家系図が空かどうか
    public var isCurrentTreeEmpty: Bool {
        currentTree?.members.isEmpty ?? true
    }

    // MARK: - Initializer

    public init() {}

    // MARK: - Configuration

    /// ModelContextを設定
    public func configure(with modelContext: ModelContext) {
        self.dataService = FamilyTreeDataService(modelContext: modelContext)
    }

    // MARK: - Data Loading

    /// 初期データを読み込み
    public func loadInitialData() async {
        guard let dataService = dataService else {
            appState = .error("データサービスが設定されていません")
            return
        }

        appState = .loading
        isLoading = true

        do {
            familyTrees = try dataService.fetchAllTrees()

            if familyTrees.isEmpty {
                appState = .empty
            } else {
                currentTree = familyTrees.first
                appState = .loaded
            }
        } catch {
            appState = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Tree Management

    /// 家系図を作成
    public func createTree(name: String, notes: String? = nil) async throws {
        guard let dataService = dataService else {
            throw FamilyTreeError.storageError("データサービスが設定されていません")
        }

        let tree = try dataService.createTree(name: name, notes: notes)
        familyTrees.insert(tree, at: 0)

        if currentTree == nil {
            currentTree = tree
        }

        if appState == .empty {
            appState = .loaded
        }
    }

    /// 家系図を選択
    public func selectTree(_ tree: FamilyTree) {
        currentTree = tree
        selectMember(nil)
        resetViewState()
    }

    /// 家系図を更新
    public func updateTree(_ tree: FamilyTree) async throws {
        guard let dataService = dataService else {
            throw FamilyTreeError.storageError("データサービスが設定されていません")
        }

        try dataService.updateTree(tree)
    }

    /// 家系図を削除
    public func deleteTree(_ tree: FamilyTree) async throws {
        guard let dataService = dataService else {
            throw FamilyTreeError.storageError("データサービスが設定されていません")
        }

        try dataService.deleteTree(tree)
        familyTrees.removeAll { $0.id == tree.id }

        if currentTree?.id == tree.id {
            currentTree = familyTrees.first
            selectMember(nil)
        }

        if familyTrees.isEmpty {
            appState = .empty
        }
    }

    // MARK: - Member Management

    /// メンバーを追加
    public func addMember(
        firstName: String,
        lastName: String,
        gender: Gender = .other,
        birthDate: Date? = nil,
        deathDate: Date? = nil,
        birthPlace: String? = nil,
        notes: String? = nil,
        profileImageData: Data? = nil
    ) async throws -> FamilyMember {
        guard let dataService = dataService else {
            throw FamilyTreeError.storageError("データサービスが設定されていません")
        }

        guard let tree = currentTree else {
            throw FamilyTreeError.treeNotFound
        }

        let member = try dataService.addMember(
            to: tree,
            firstName: firstName,
            lastName: lastName,
            gender: gender,
            birthDate: birthDate,
            deathDate: deathDate,
            birthPlace: birthPlace,
            notes: notes,
            profileImageData: profileImageData
        )

        return member
    }

    /// メンバーを選択（直系血族ハイライトも更新）
    ///
    /// nil を渡すとハイライトを解除。タップで選択→再タップで解除を実現する場合は
    /// 呼び出し側で同じメンバーかを判定して nil を渡す。
    public func selectMember(_ member: FamilyMember?) {
        selectedMember = member
        if let member, let tree = currentTree {
            highlightedIDs = tree.directBloodline(of: member)
        } else {
            highlightedIDs = nil
        }
    }

    /// 指定 ID のノードを薄く表示すべきか
    public func shouldDim(id: UUID) -> Bool {
        guard let highlightedIDs else { return false }
        return !highlightedIDs.contains(id)
    }

    /// メンバーを更新
    public func updateMember(_ member: FamilyMember) async throws {
        guard let dataService = dataService else {
            throw FamilyTreeError.storageError("データサービスが設定されていません")
        }

        try dataService.updateMember(member)
    }

    /// メンバーを削除
    public func deleteMember(_ member: FamilyMember) async throws {
        guard let dataService = dataService else {
            throw FamilyTreeError.storageError("データサービスが設定されていません")
        }

        guard let tree = currentTree else {
            throw FamilyTreeError.treeNotFound
        }

        try dataService.deleteMember(member, from: tree)

        if selectedMember?.id == member.id {
            selectMember(nil)
        }
    }

    // MARK: - Relationship Management

    /// 親子関係を設定
    public func setParentChild(parent: FamilyMember, child: FamilyMember) async throws {
        guard let dataService = dataService else {
            throw FamilyTreeError.storageError("データサービスが設定されていません")
        }

        try dataService.setParentChild(parent: parent, child: child)
    }

    /// 親子関係を解除
    public func removeParentChild(parent: FamilyMember, child: FamilyMember) async throws {
        guard let dataService = dataService else {
            throw FamilyTreeError.storageError("データサービスが設定されていません")
        }

        try dataService.removeParentChild(parent: parent, child: child)
    }

    /// 婚姻関係を作成
    @discardableResult
    public func createMarriage(
        partner1: FamilyMember,
        partner2: FamilyMember,
        marriageDate: Date? = nil,
        marriagePlace: String? = nil
    ) async throws -> Marriage {
        guard let dataService = dataService else {
            throw FamilyTreeError.storageError("データサービスが設定されていません")
        }

        return try dataService.createMarriage(
            partner1: partner1,
            partner2: partner2,
            marriageDate: marriageDate,
            marriagePlace: marriagePlace
        )
    }

    /// 婚姻関係を削除
    public func deleteMarriage(_ marriage: Marriage) async throws {
        guard let dataService = dataService else {
            throw FamilyTreeError.storageError("データサービスが設定されていません")
        }

        try dataService.deleteMarriage(marriage)
    }

    /// 離婚を設定
    public func setDivorce(_ marriage: Marriage, divorceDate: Date) async throws {
        guard let dataService = dataService else {
            throw FamilyTreeError.storageError("データサービスが設定されていません")
        }

        try dataService.setDivorce(marriage, divorceDate: divorceDate)
    }

    // MARK: - View State Management

    /// ビュー状態をリセット
    public func resetViewState() {
        zoomScale = 0.55
        panOffset = .zero
        searchQuery = ""
        showOnlyAlive = false
        selectedGeneration = nil
    }

    /// ズームをリセット
    public func resetZoom() {
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = 0.55
            panOffset = .zero
        }
    }

    /// ズームイン
    public func zoomIn() {
        let newScale = min(zoomScale * 1.25, 3.0)
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = newScale
        }
    }

    /// ズームアウト
    public func zoomOut() {
        let newScale = max(zoomScale / 1.25, 0.3)
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = newScale
        }
    }

    // MARK: - Error Handling

    /// エラーをクリア
    public func clearError() {
        errorMessage = nil
    }
}
