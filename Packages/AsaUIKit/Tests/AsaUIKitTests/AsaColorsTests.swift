import Testing
import SwiftUI
@testable import AsaUIKit

struct AsaColorsTests {
    
    @Test("ブランドカラーの定義確認テスト")
    func brandColorDefinitions() throws {
        // 基本ブランドカラーが定義されていることを確認
        #expect(AsaColors.coffeeBrown != Color.clear)
        #expect(AsaColors.mocha != Color.clear)
        #expect(AsaColors.softCream != Color.clear)
        #expect(AsaColors.darkSlate != Color.clear)
        #expect(AsaColors.mutedSage != Color.clear)
    }
    
    @Test("Kanban専用カラーの定義確認テスト")
    func kanbanColorDefinitions() throws {
        #expect(AsaColors.todoColumn != Color.clear)
        #expect(AsaColors.inProgressColumn != Color.clear)
        #expect(AsaColors.doneColumn != Color.clear)
    }
    
    @Test("カード背景色の定義確認テスト")
    func cardBackgroundColor() throws {
        #expect(AsaColors.cardBackground != Color.clear)
        
        // 半透明の白色であることを確認（完全な白色ではない）
        #expect(AsaColors.cardBackground != Color.white)
    }
    
    @Test("色の一意性確認テスト")
    func colorUniqueness() throws {
        // 主要ブランドカラーがそれぞれ異なることを確認
        #expect(AsaColors.coffeeBrown != AsaColors.mocha)
        #expect(AsaColors.coffeeBrown != AsaColors.softCream)
        #expect(AsaColors.mocha != AsaColors.softCream)
        #expect(AsaColors.darkSlate != AsaColors.mutedSage)
    }
}

struct TaskPriorityTests {
    
    @Test("TaskPriority表示名テスト")
    func taskPriorityDisplayNames() throws {
        #expect(TaskPriority.high.displayName == "高")
        #expect(TaskPriority.medium.displayName == "中")
        #expect(TaskPriority.low.displayName == "低")
    }
    
    @Test("TaskPriorityのrawValue確認テスト")
    func taskPriorityRawValues() throws {
        #expect(TaskPriority.high.rawValue == "high")
        #expect(TaskPriority.medium.rawValue == "medium")
        #expect(TaskPriority.low.rawValue == "low")
    }
    
    @Test("TaskPriorityのCaseIterable適合テスト")
    func taskPriorityAllCases() throws {
        let allCases = TaskPriority.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.high))
        #expect(allCases.contains(.medium))
        #expect(allCases.contains(.low))
    }
    
    @Test("TaskPriorityのIdentifiable適合テスト")
    func taskPriorityIdentifiable() throws {
        #expect(TaskPriority.high.id == "high")
        #expect(TaskPriority.medium.id == "medium")
        #expect(TaskPriority.low.id == "low")
    }
}