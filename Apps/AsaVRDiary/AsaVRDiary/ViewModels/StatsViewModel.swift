//
//  StatsViewModel.swift
//  AsaVRDiary
//
//  統計ViewModel
//

import Foundation

/// 統計ViewModel
@MainActor
@Observable
final class StatsViewModel {

    // MARK: - Properties

    /// 統計データ
    private(set) var stats: DiaryStats = .empty

    /// 読み込み中フラグ
    private(set) var isLoading: Bool = false

    /// 選択中の期間
    var selectedPeriod: StatsPeriod = .month

    /// データサービス
    private let dataService: DiaryDataService

    // MARK: - Initialization

    init(dataService: DiaryDataService? = nil) {
        self.dataService = dataService ?? DiaryDataService()
    }

    // MARK: - Public Methods

    /// 統計を読み込み
    func loadStats() {
        isLoading = true
        stats = dataService.calculateStats()
        isLoading = false
    }

    /// カテゴリ別の割合を取得
    func categoryPercentages() -> [(DiaryCategory, Double)] {
        let total = Double(stats.totalEntries)
        guard total > 0 else { return [] }

        return stats.categoryCount
            .filter { $0.value > 0 }
            .map { ($0.key, Double($0.value) / total * 100) }
            .sorted { $0.1 > $1.1 }
    }

    /// 気分別の割合を取得
    func moodPercentages() -> [(DiaryMood, Double)] {
        let total = Double(stats.totalEntries)
        guard total > 0 else { return [] }

        return stats.moodCount
            .filter { $0.value > 0 }
            .map { ($0.key, Double($0.value) / total * 100) }
            .sorted { $0.1 > $1.1 }
    }

    /// 週ごとのエントリー数（チャート用）
    func weeklyChartData() -> [(String, Int)] {
        stats.weeklyEntries.map { ($0.formattedWeek, $0.count) }
    }

    /// 月ごとのエントリー数（チャート用）
    func monthlyChartData() -> [(String, Int)] {
        stats.monthlyEntries.map { ($0.formattedMonth, $0.count) }
    }

    /// 気分トレンドを取得
    func moodTrend() -> MoodTrend {
        guard stats.weeklyEntries.count >= 2 else {
            return .stable
        }

        let recent = stats.weeklyEntries.suffix(2)
        guard let lastWeek = recent.first,
              let thisWeek = recent.last else {
            return .stable
        }

        if thisWeek.count > lastWeek.count {
            return .increasing
        } else if thisWeek.count < lastWeek.count {
            return .decreasing
        } else {
            return .stable
        }
    }

    /// ストリーク状態を取得
    func streakStatus() -> StreakStatus {
        let days = stats.streakDays
        if days >= 30 {
            return .excellent
        } else if days >= 7 {
            return .good
        } else if days >= 3 {
            return .building
        } else if days >= 1 {
            return .started
        } else {
            return .none
        }
    }
}

// MARK: - Supporting Types

/// 統計期間
enum StatsPeriod: String, CaseIterable {
    case week = "week"
    case month = "month"
    case year = "year"

    var displayName: String {
        switch self {
        case .week: return "週"
        case .month: return "月"
        case .year: return "年"
        }
    }
}

/// 気分トレンド
enum MoodTrend {
    case increasing
    case decreasing
    case stable

    var icon: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var description: String {
        switch self {
        case .increasing: return "増加傾向"
        case .decreasing: return "減少傾向"
        case .stable: return "安定"
        }
    }
}

/// ストリーク状態
enum StreakStatus {
    case none
    case started
    case building
    case good
    case excellent

    var message: String {
        switch self {
        case .none: return "今日から始めよう！"
        case .started: return "良いスタート！"
        case .building: return "習慣になりつつあります"
        case .good: return "素晴らしい継続！"
        case .excellent: return "驚異的な継続力！"
        }
    }

    var icon: String {
        switch self {
        case .none: return "flame"
        case .started: return "flame.fill"
        case .building: return "flame.fill"
        case .good: return "flame.fill"
        case .excellent: return "flame.fill"
        }
    }
}
