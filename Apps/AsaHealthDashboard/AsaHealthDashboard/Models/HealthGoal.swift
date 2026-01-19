//
//  HealthGoal.swift
//  AsaHealthDashboard
//
//  目標設定モデル（SwiftData）
//

import Foundation
import SwiftData

/// 健康目標設定
@Model
final class HealthGoal {
    var id: UUID
    var categoryRawValue: String
    var targetValue: Double
    var createdAt: Date
    var updatedAt: Date

    /// カテゴリ（computed property）
    var category: HealthCategory {
        get {
            HealthCategory(rawValue: categoryRawValue) ?? .steps
        }
        set {
            categoryRawValue = newValue.rawValue
        }
    }

    init(category: HealthCategory, targetValue: Double) {
        self.id = UUID()
        self.categoryRawValue = category.rawValue
        self.targetValue = targetValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// 目標値を更新
    func updateTarget(_ newValue: Double) {
        targetValue = newValue
        updatedAt = Date()
    }
}

// MARK: - HealthGoal配列の拡張

extension Array where Element == HealthGoal {
    /// カテゴリで目標を検索
    func goal(for category: HealthCategory) -> HealthGoal? {
        first { $0.category == category }
    }

    /// カテゴリの目標値を取得（なければデフォルト値）
    func targetValue(for category: HealthCategory) -> Double {
        goal(for: category)?.targetValue ?? category.defaultGoal
    }
}
