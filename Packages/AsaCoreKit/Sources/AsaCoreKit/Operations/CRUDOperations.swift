//
//  CRUDOperations.swift
//  AsaCoreKit
//
//  標準CRUD操作プロトコルと実装
//

import Foundation

// MARK: - Identifiable + Codable

/// CRUD操作対象の基本要件
public typealias CRUDModel = Identifiable & Codable & Sendable

// MARK: - CRUDOperations Protocol

/// 標準CRUD操作プロトコル（構造体用）
@MainActor
public protocol CRUDOperations {
    associatedtype Model: CRUDModel
    
    /// データコレクション
    var items: [Model] { get set }
    
    /// 永続化キー
    var persistenceKey: String { get }
    
    /// データ読み込み
    mutating func loadItems() async throws
    
    /// データ保存
    func saveItems() async throws
    
    /// アイテム追加
    /// - Parameter item: 追加するアイテム
    mutating func addItem(_ item: Model) async throws
    
    /// アイテム更新
    /// - Parameter item: 更新するアイテム
    mutating func updateItem(_ item: Model) async throws
    
    /// アイテム削除（ID指定）
    /// - Parameter id: 削除するアイテムのID
    mutating func deleteItem(id: Model.ID) async throws
    
    /// アイテム削除（複数）
    /// - Parameter ids: 削除するアイテムのID配列
    mutating func deleteItems(ids: [Model.ID]) async throws
    
    /// アイテム取得（ID指定）
    /// - Parameter id: 取得するアイテムのID
    /// - Returns: 該当アイテム（存在しない場合はnil）
    func getItem(id: Model.ID) -> Model?
    
    /// アイテム存在確認
    /// - Parameter id: 確認するアイテムのID
    /// - Returns: 存在するかどうか
    func itemExists(id: Model.ID) -> Bool
    
    /// 全アイテムクリア
    mutating func clearAllItems() async throws
    
    /// アイテム数取得
    var itemCount: Int { get }
}

// MARK: - CRUDOperationsClass Protocol

/// 標準CRUD操作プロトコル（クラス用）
@MainActor
public protocol CRUDOperationsClass {
    associatedtype Model: CRUDModel
    
    /// データコレクション
    var items: [Model] { get set }
    
    /// 永続化キー
    var persistenceKey: String { get }
    
    /// データ読み込み
    func loadItems() async throws
    
    /// データ保存
    func saveItems() async throws
    
    /// アイテム追加
    /// - Parameter item: 追加するアイテム
    func addItem(_ item: Model) async throws
    
    /// アイテム更新
    /// - Parameter item: 更新するアイテム
    func updateItem(_ item: Model) async throws
    
    /// アイテム削除（ID指定）
    /// - Parameter id: 削除するアイテムのID
    func deleteItem(id: Model.ID) async throws
    
    /// アイテム削除（複数）
    /// - Parameter ids: 削除するアイテムのID配列
    func deleteItems(ids: [Model.ID]) async throws
    
    /// アイテム取得（ID指定）
    /// - Parameter id: 取得するアイテムのID
    /// - Returns: 該当アイテム（存在しない場合はnil）
    func getItem(id: Model.ID) -> Model?
    
    /// アイテム存在確認
    /// - Parameter id: 確認するアイテムのID
    /// - Returns: 存在するかどうか
    func itemExists(id: Model.ID) -> Bool
    
    /// 全アイテムクリア
    func clearAllItems() async throws
    
    /// アイテム数取得
    var itemCount: Int { get }
}

// MARK: - CRUDOperations Default Implementation

extension CRUDOperations {
    
    /// データ読み込み（デフォルト実装）
    public mutating func loadItems() async throws {
        let loadedItems: [Model] = try await PersistenceManager.shared.loadAsync([Model].self, forKey: persistenceKey) ?? []
        items = loadedItems
    }
    
    /// データ保存（デフォルト実装）
    public func saveItems() async throws {
        try await PersistenceManager.shared.saveAsync(items, forKey: persistenceKey)
    }
    
    /// アイテム追加
    /// - Parameter item: 追加するアイテム
    public mutating func addItem(_ item: Model) async throws {
        // 重複チェック
        if itemExists(id: item.id) {
            throw AsaCoreError.duplicateItem("ID: \(item.id)")
        }
        
        items.append(item)
        try await saveItems()
    }
    
    /// アイテム更新
    /// - Parameter item: 更新するアイテム
    public mutating func updateItem(_ item: Model) async throws {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            throw AsaCoreError.itemNotFound("ID: \(item.id)")
        }
        
        items[index] = item
        try await saveItems()
    }
    
    /// アイテム削除（ID指定）
    /// - Parameter id: 削除するアイテムのID
    public mutating func deleteItem(id: Model.ID) async throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw AsaCoreError.itemNotFound("ID: \(id)")
        }
        
        items.remove(at: index)
        try await saveItems()
    }
    
    /// アイテム削除（複数）
    /// - Parameter ids: 削除するアイテムのID配列
    public mutating func deleteItems(ids: [Model.ID]) async throws {
        items.removeAll { item in ids.contains(item.id) }
        try await saveItems()
    }
    
    /// アイテム取得（ID指定）
    /// - Parameter id: 取得するアイテムのID  
    /// - Returns: 該当アイテム（存在しない場合はnil）
    public func getItem(id: Model.ID) -> Model? {
        return items.first { $0.id == id }
    }
    
    /// アイテム存在確認
    /// - Parameter id: 確認するアイテムのID
    /// - Returns: 存在するかどうか
    public func itemExists(id: Model.ID) -> Bool {
        return items.contains { $0.id == id }
    }
    
    /// 全アイテムクリア
    public mutating func clearAllItems() async throws {
        items.removeAll()
        try await saveItems()
    }
    
    /// アイテム数取得
    public var itemCount: Int {
        return items.count
    }
}

// MARK: - CRUDOperationsClass Default Implementation

extension CRUDOperationsClass {
    
    /// アイテム取得（ID指定）
    /// - Parameter id: 取得するアイテムのID  
    /// - Returns: 該当アイテム（存在しない場合はnil）
    public func getItem(id: Model.ID) -> Model? {
        return items.first { $0.id == id }
    }
    
    /// アイテム存在確認
    /// - Parameter id: 確認するアイテムのID
    /// - Returns: 存在するかどうか
    public func itemExists(id: Model.ID) -> Bool {
        return items.contains { $0.id == id }
    }
    
    /// アイテム数取得
    public var itemCount: Int {
        return items.count
    }
}

// MARK: - CRUDManager

/// 汎用CRUDマネージャー実装
@MainActor
@Observable
public class CRUDManager<Model: CRUDModel>: BaseViewModel, CRUDOperationsClass {
    
    // MARK: - CRUDOperations Requirements
    
    /// データコレクション
    public var items: [Model] = []
    
    /// 永続化キー
    public let persistenceKey: String
    
    // MARK: - Additional Properties
    
    /// 選択中のアイテム
    public var selectedItem: Model?
    
    /// フィルタリング用検索テキスト
    public var searchText: String = ""
    
    /// ソート順序
    public var sortDescending: Bool = false
    
    // MARK: - Computed Properties
    
    /// フィルタリング済みアイテム
    public var filteredItems: [Model] {
        var result = items
        
        // 検索フィルタリング（Modelが文字列検索対応している場合）
        if !searchText.isEmpty, let searchableItems = items as? [any TextSearchable] {
            result = searchableItems.filter { item in
                item.searchableText.localizedCaseInsensitiveContains(searchText)
            } as? [Model] ?? items
        }
        
        return result
    }
    
    /// アイテムが空かどうか
    public var isEmpty: Bool {
        return items.isEmpty
    }
    
    // MARK: - Initialization
    
    /// 初期化
    /// - Parameter persistenceKey: 永続化キー
    public init(persistenceKey: String) {
        self.persistenceKey = persistenceKey
        super.init()
    }
    
    // MARK: - CRUDOperationsClass Protocol Implementation
    
    /// データ読み込み
    public func loadItems() async throws {
        let loadedItems: [Model] = try await PersistenceManager.shared.loadAsync([Model].self, forKey: persistenceKey) ?? []
        items = loadedItems
    }
    
    /// データ保存
    public func saveItems() async throws {
        try await PersistenceManager.shared.saveAsync(items, forKey: persistenceKey)
    }
    
    /// アイテム追加
    /// - Parameter item: 追加するアイテム
    public func addItem(_ item: Model) async throws {
        // 重複チェック
        if itemExists(id: item.id) {
            throw AsaCoreError.duplicateItem("ID: \(item.id)")
        }
        
        items.append(item)
        try await saveItems()
    }
    
    /// アイテム更新
    /// - Parameter item: 更新するアイテム
    public func updateItem(_ item: Model) async throws {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            throw AsaCoreError.itemNotFound("ID: \(item.id)")
        }
        
        items[index] = item
        try await saveItems()
    }
    
    /// アイテム削除（ID指定）
    /// - Parameter id: 削除するアイテムのID
    public func deleteItem(id: Model.ID) async throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw AsaCoreError.itemNotFound("ID: \(id)")
        }
        
        items.remove(at: index)
        try await saveItems()
    }
    
    /// アイテム削除（複数）
    /// - Parameter ids: 削除するアイテムのID配列
    public func deleteItems(ids: [Model.ID]) async throws {
        items.removeAll { item in ids.contains(item.id) }
        try await saveItems()
    }
    
    /// 全アイテムクリア
    public func clearAllItems() async throws {
        items.removeAll()
        try await saveItems()
    }
    
    // MARK: - Lifecycle Override
    
    public override func initialize() {
        super.initialize()
        refresh()
    }
    
    public override func loadData() async throws {
        try await loadItems()
    }
    
    public override func saveData() async throws {
        try await saveItems()
    }
    
    // MARK: - Extended CRUD Operations
    
    /// アイテム追加（同期版）
    /// - Parameter item: 追加するアイテム
    public func addItemSync(_ item: Model) {
        safeAsync {
            try await self.addItem(item)
        }
    }
    
    /// アイテム更新（同期版）
    /// - Parameter item: 更新するアイテム
    public func updateItemSync(_ item: Model) {
        safeAsync {
            try await self.updateItem(item)
        }
    }
    
    /// アイテム削除（同期版）
    /// - Parameter id: 削除するアイテムのID
    public func deleteItemSync(id: Model.ID) {
        safeAsync {
            try await self.deleteItem(id: id)
        }
    }
    
    /// インデックス指定削除
    /// - Parameter indexSet: 削除するインデックスセット
    public func deleteItems(at indexSet: IndexSet) {
        let idsToDelete = indexSet.map { items[$0].id }
        safeAsync {
            try await self.deleteItems(ids: idsToDelete)
        }
    }
    
    /// アイテム並び替え
    /// - Parameters:
    ///   - source: 移動元インデックス
    ///   - destination: 移動先インデックス
    public func moveItems(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        
        safeAsync {
            try await self.saveItems()
        }
    }
}

// MARK: - TextSearchable Protocol

/// テキスト検索対応プロトコル
public protocol TextSearchable {
    /// 検索対象テキスト
    var searchableText: String { get }
}

// MARK: - Collection Extensions

extension Collection where Element: CRUDModel {
    
    /// ID指定でアイテム取得
    /// - Parameter id: 取得するアイテムのID
    /// - Returns: 該当アイテム（存在しない場合はnil）
    public func item(with id: Element.ID) -> Element? {
        return first { $0.id == id }
    }
    
    /// ID配列取得
    public var ids: [Element.ID] {
        return map { $0.id }
    }
}