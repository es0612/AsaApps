//
//  AsaCoreKitTests.swift
//  AsaCoreKitTests
//
//  AsaCoreKit統合テスト
//

import Testing
import Foundation
@testable import AsaCoreKit

// MARK: - Test Models

struct TestItem: CRUDModel {
    let id: UUID
    var name: String
    var value: Int
    
    init(name: String, value: Int = 0) {
        self.id = UUID()
        self.name = name
        self.value = value
    }
}

extension TestItem: TextSearchable {
    var searchableText: String {
        return name
    }
}

// MARK: - AsaCoreKit Main Tests

struct AsaCoreKitTests {
    
    @Test("AsaCoreKit基本情報テスト")
    func testAsaCoreKitInfo() {
        #expect(AsaCoreKitLib.version == "1.0.0")
        
        // デバッグモード切り替えテスト
        AsaCoreKitLib.debugMode = true
        #expect(AsaCoreKitLib.debugMode == true)
        
        AsaCoreKitLib.debugMode = false
        #expect(AsaCoreKitLib.debugMode == false)
    }
}