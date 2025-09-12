//
//  PersistenceManagerTests.swift
//  AsaCoreKitTests
//
//  PersistenceManagerテスト
//

import Testing
import Foundation
@testable import AsaCoreKit

struct PersistenceManagerTests {
    
    private let testKey = "TestKey"
    private var manager: PersistenceManager {
        // テスト用のPersistenceManagerを作成（専用UserDefaults使用）
        let testDefaults = UserDefaults(suiteName: "AsaCoreKitTests") ?? .standard
        return PersistenceManager(userDefaults: testDefaults, keyPrefix: "Test")
    }
    
    @Test("基本的なデータ保存・読み込みテスト")
    func testBasicSaveAndLoad() throws {
        let testData = TestItem(name: "テストアイテム", value: 42)
        
        // 保存
        try manager.save(testData, forKey: testKey)
        
        // 読み込み
        let loadedData = try manager.load(TestItem.self, forKey: testKey)
        
        #expect(loadedData != nil)
        #expect(loadedData?.name == "テストアイテム")
        #expect(loadedData?.value == 42)
        
        // クリーンアップ
        manager.remove(forKey: testKey)
    }
    
    @Test("配列データの保存・読み込みテスト")
    func testArraySaveAndLoad() throws {
        let testArray = [
            TestItem(name: "アイテム1", value: 1),
            TestItem(name: "アイテム2", value: 2),
            TestItem(name: "アイテム3", value: 3)
        ]
        
        // 配列保存
        try manager.saveArray(testArray, forKey: testKey)
        
        // 配列読み込み
        let loadedArray = try manager.loadArray(TestItem.self, forKey: testKey)
        
        #expect(loadedArray.count == 3)
        #expect(loadedArray[0].name == "アイテム1")
        #expect(loadedArray[1].value == 2)
        
        // クリーンアップ
        manager.remove(forKey: testKey)
    }
    
    @Test("存在しないキーの読み込みテスト")
    func testLoadNonExistentKey() throws {
        let loadedData = try manager.load(TestItem.self, forKey: "NonExistentKey")
        #expect(loadedData == nil)
        
        let loadedArray = try manager.loadArray(TestItem.self, forKey: "NonExistentKey")
        #expect(loadedArray.isEmpty)
    }
    
    @Test("データ削除テスト")
    func testRemoveData() throws {
        let testData = TestItem(name: "削除テスト", value: 999)
        
        // 保存
        try manager.save(testData, forKey: testKey)
        #expect(manager.exists(forKey: testKey) == true)
        
        // 削除
        manager.remove(forKey: testKey)
        #expect(manager.exists(forKey: testKey) == false)
        
        // 読み込み確認（存在しないはず）
        let loadedData = try manager.load(TestItem.self, forKey: testKey)
        #expect(loadedData == nil)
    }
    
    @Test("全データクリアテスト")
    func testClearAll() throws {
        // 複数のテストデータ保存
        try manager.save(TestItem(name: "アイテム1", value: 1), forKey: "key1")
        try manager.save(TestItem(name: "アイテム2", value: 2), forKey: "key2")
        try manager.save(TestItem(name: "アイテム3", value: 3), forKey: "key3")
        
        // 存在確認
        #expect(manager.exists(forKey: "key1") == true)
        #expect(manager.exists(forKey: "key2") == true)
        #expect(manager.exists(forKey: "key3") == true)
        
        // 全削除
        manager.clearAll()
        
        // 削除確認
        #expect(manager.exists(forKey: "key1") == false)
        #expect(manager.exists(forKey: "key2") == false)
        #expect(manager.exists(forKey: "key3") == false)
    }
    
    @Test("非同期操作テスト")
    func testAsyncOperations() async throws {
        let testData = TestItem(name: "非同期テスト", value: 555)
        
        // 非同期保存
        try await manager.saveAsync(testData, forKey: testKey)
        
        // 非同期読み込み
        let loadedData = try await manager.loadAsync(TestItem.self, forKey: testKey)
        
        #expect(loadedData != nil)
        #expect(loadedData?.name == "非同期テスト")
        #expect(loadedData?.value == 555)
        
        // クリーンアップ
        manager.remove(forKey: testKey)
    }
    
    @Test("辞書データの保存・読み込みテスト")
    func testDictionarySaveAndLoad() throws {
        let testDict: [String: TestItem] = [
            "item1": TestItem(name: "辞書アイテム1", value: 100),
            "item2": TestItem(name: "辞書アイテム2", value: 200)
        ]
        
        // 辞書保存
        try manager.saveDictionary(testDict, forKey: testKey)
        
        // 辞書読み込み
        let loadedDict = try manager.loadDictionary(TestItem.self, forKey: testKey)
        
        #expect(loadedDict.count == 2)
        #expect(loadedDict["item1"]?.name == "辞書アイテム1")
        #expect(loadedDict["item2"]?.value == 200)
        
        // クリーンアップ
        manager.remove(forKey: testKey)
    }
}