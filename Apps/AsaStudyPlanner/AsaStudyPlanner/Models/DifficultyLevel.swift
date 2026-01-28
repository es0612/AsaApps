import Foundation
import SwiftUI

/// 学習項目の難易度レベル
/// 難易度は時間帯との組み合わせで最適化に使用される
enum DifficultyLevel: String, CaseIterable, Codable, Sendable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case expert = "expert"

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .easy: return "やさしい"
        case .medium: return "普通"
        case .hard: return "難しい"
        case .expert: return "上級"
        }
    }

    var icon: String {
        switch self {
        case .easy: return "star"
        case .medium: return "star.leadinghalf.filled"
        case .hard: return "star.fill"
        case .expert: return "star.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .orange
        case .expert: return .red
        }
    }

    // MARK: - AI Optimization Properties

    /// 難易度に基づく集中力要求度（0.0-1.0）
    var concentrationRequirement: Double {
        switch self {
        case .easy: return 0.3
        case .medium: return 0.5
        case .hard: return 0.75
        case .expert: return 1.0
        }
    }

    /// 朝の時間帯（5-9時）での推奨度
    /// 難しい内容は朝が最適
    var morningBonus: Double {
        switch self {
        case .easy: return 0.0      // 朝でなくても良い
        case .medium: return 0.1
        case .hard: return 0.2
        case .expert: return 0.3    // 朝に学習すべき
        }
    }

    /// 夜の時間帯（21時以降）での推奨度低下
    var eveningPenalty: Double {
        switch self {
        case .easy: return 0.0      // 夜でも問題なし
        case .medium: return 0.1
        case .hard: return 0.2
        case .expert: return 0.4    // 夜は避けるべき
        }
    }

    /// 推奨休憩間隔（分）
    var recommendedBreakInterval: Int {
        switch self {
        case .easy: return 45
        case .medium: return 35
        case .hard: return 25
        case .expert: return 20
        }
    }

    /// 数値インデックス（0-3）
    var numericValue: Int {
        switch self {
        case .easy: return 0
        case .medium: return 1
        case .hard: return 2
        case .expert: return 3
        }
    }
}
