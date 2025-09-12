//
//  PersistenceManager.swift
//  AsaCoreKit
//
//  UserDefaults + JSON統合データ永続化マネージャー
//

import Foundation

// MARK: - PersistenceProtocol

/// データ永続化プロトコル
public protocol PersistenceProtocol {
    
    /// データ保存
    /// - Parameters:
    ///   - object: 保存するオブジェクト
    ///   - key: 保存キー
    func save<T: Codable>(_ object: T, forKey key: String) throws
    
    /// データ読み込み
    /// - Parameters:
    ///   - type: 読み込む型
    ///   - key: 読み込みキー
    /// - Returns: 読み込まれたオブジェクト（存在しない場合はnil）
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T?
    
    /// データ削除
    /// - Parameter key: 削除キー
    func remove(forKey key: String)
    
    /// データ存在確認
    /// - Parameter key: 確認キー
    /// - Returns: データが存在するかどうか
    func exists(forKey key: String) -> Bool
    
    /// 全データクリア（開発・テスト用）
    func clearAll()
}

// MARK: - PersistenceManager

/// UserDefaults + JSON統合データ永続化マネージャー
public final class PersistenceManager: PersistenceProtocol, @unchecked Sendable {
    
    // MARK: - Singleton
    
    /// 共有インスタンス
    public static let shared = PersistenceManager()
    
    // MARK: - Private Properties
    
    private let userDefaults: UserDefaults
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    private let keyPrefix: String
    
    // MARK: - Initialization
    
    /// 初期化
    /// - Parameters:
    ///   - userDefaults: 使用するUserDefaultsインスタンス（デフォルト：standard）
    ///   - keyPrefix: キーのプレフィックス（デフォルト：AsaApps）
    public init(
        userDefaults: UserDefaults = .standard,
        keyPrefix: String = "AsaApps"
    ) {
        self.userDefaults = userDefaults
        self.keyPrefix = keyPrefix
        
        // JSONエンコーダー/デコーダーの設定
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601
        
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - PersistenceProtocol Implementation
    
    /// データ保存
    /// - Parameters:
    ///   - object: 保存するCodableオブジェクト
    ///   - key: 保存キー
    public func save<T: Codable>(_ object: T, forKey key: String) throws {
        let prefixedKey = makeKey(key)
        
        do {
            let data = try jsonEncoder.encode(object)
            userDefaults.set(data, forKey: prefixedKey)
            
            if AsaCoreKitLib.debugMode {
                print("✅ PersistenceManager: Saved \(T.self) to key: \(prefixedKey)")
            }
        } catch {
            if AsaCoreKitLib.debugMode {
                print("❌ PersistenceManager: Failed to encode \(T.self) for key: \(prefixedKey)")
            }
            throw AsaCoreError.encodingFailed
        }
    }
    
    /// データ読み込み
    /// - Parameters:
    ///   - type: 読み込む型
    ///   - key: 読み込みキー
    /// - Returns: 読み込まれたオブジェクト（存在しない場合はnil）
    public func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        let prefixedKey = makeKey(key)
        
        guard let data = userDefaults.data(forKey: prefixedKey) else {
            if AsaCoreKitLib.debugMode {
                print("ℹ️ PersistenceManager: No data found for key: \(prefixedKey)")
            }
            return nil
        }
        
        do {
            let object = try jsonDecoder.decode(type, from: data)
            
            if AsaCoreKitLib.debugMode {
                print("✅ PersistenceManager: Loaded \(T.self) from key: \(prefixedKey)")
            }
            
            return object
        } catch {
            if AsaCoreKitLib.debugMode {
                print("❌ PersistenceManager: Failed to decode \(T.self) from key: \(prefixedKey)")
            }
            throw AsaCoreError.decodingFailed
        }
    }
    
    /// データ削除
    /// - Parameter key: 削除キー
    public func remove(forKey key: String) {
        let prefixedKey = makeKey(key)
        userDefaults.removeObject(forKey: prefixedKey)
        
        if AsaCoreKitLib.debugMode {
            print("🗑️ PersistenceManager: Removed data for key: \(prefixedKey)")
        }
    }
    
    /// データ存在確認
    /// - Parameter key: 確認キー
    /// - Returns: データが存在するかどうか
    public func exists(forKey key: String) -> Bool {
        let prefixedKey = makeKey(key)
        return userDefaults.object(forKey: prefixedKey) != nil
    }
    
    /// 全データクリア（開発・テスト用）
    public func clearAll() {
        let keys = userDefaults.dictionaryRepresentation().keys
        let prefixedKeys = keys.filter { $0.hasPrefix(keyPrefix) }
        
        for key in prefixedKeys {
            userDefaults.removeObject(forKey: key)
        }
        
        if AsaCoreKitLib.debugMode {
            print("🧹 PersistenceManager: Cleared \(prefixedKeys.count) keys")
        }
    }
    
    // MARK: - Convenience Methods
    
    /// 配列データの安全な保存
    /// - Parameters:
    ///   - array: 保存する配列
    ///   - key: 保存キー
    public func saveArray<T: Codable>(_ array: [T], forKey key: String) throws {
        try save(array, forKey: key)
    }
    
    /// 配列データの安全な読み込み
    /// - Parameters:
    ///   - type: 配列要素の型
    ///   - key: 読み込みキー
    /// - Returns: 読み込まれた配列（存在しない場合は空配列）
    public func loadArray<T: Codable>(_ type: T.Type, forKey key: String) throws -> [T] {
        return try load([T].self, forKey: key) ?? []
    }
    
    /// 辞書データの安全な保存
    /// - Parameters:
    ///   - dictionary: 保存する辞書
    ///   - key: 保存キー
    public func saveDictionary<T: Codable>(_ dictionary: [String: T], forKey key: String) throws {
        try save(dictionary, forKey: key)
    }
    
    /// 辞書データの安全な読み込み
    /// - Parameters:
    ///   - type: 辞書値の型
    ///   - key: 読み込みキー
    /// - Returns: 読み込まれた辞書（存在しない場合は空辞書）
    public func loadDictionary<T: Codable>(_ type: T.Type, forKey key: String) throws -> [String: T] {
        return try load([String: T].self, forKey: key) ?? [:]
    }
    
    // MARK: - Private Methods
    
    private func makeKey(_ key: String) -> String {
        return "\(keyPrefix)_\(key)"
    }
}

// MARK: - PersistenceManager + Async Support

extension PersistenceManager {
    
    /// 非同期データ保存
    /// - Parameters:
    ///   - object: 保存するオブジェクト
    ///   - key: 保存キー
    public func saveAsync<T: Codable & Sendable>(_ object: T, forKey key: String) async throws {
        try await Task.detached(priority: .utility) {
            try self.save(object, forKey: key)
        }.value
    }
    
    /// 非同期データ読み込み
    /// - Parameters:
    ///   - type: 読み込む型
    ///   - key: 読み込みキー
    /// - Returns: 読み込まれたオブジェクト
    public func loadAsync<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async throws -> T? {
        try await Task.detached(priority: .utility) {
            try self.load(type, forKey: key)
        }.value
    }
}