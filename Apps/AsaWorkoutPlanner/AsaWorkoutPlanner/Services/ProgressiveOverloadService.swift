//
//  ProgressiveOverloadService.swift
//  AsaWorkoutPlanner
//
//  プログレッシブ・オーバーロード計算サービス
//  過去のパフォーマンスに基づいて重量増加を提案
//

import Foundation

/// プログレッシブ・オーバーロードの提案結果
struct OverloadSuggestion {
    let exerciseName: String
    let currentWeight: Double
    let suggestedWeight: Double
    let increasePercentage: Double
    let reason: String
    let confidence: ConfidenceLevel

    enum ConfidenceLevel {
        case high      // 十分なデータがあり、自信を持って提案
        case medium    // データはあるが、注意が必要
        case low       // データ不足、控えめな提案

        var description: String {
            switch self {
            case .high: return "高い自信度"
            case .medium: return "中程度の自信度"
            case .low: return "低い自信度"
            }
        }
    }
}

class ProgressiveOverloadService {
    // MARK: - Properties

    private let minIncreasePercentage = 0.025  // 2.5%
    private let standardIncreasePercentage = 0.05  // 5%
    private let maxIncreasePercentage = 0.10  // 10%
    private let minSessionsForAnalysis = 3

    // MARK: - Public Methods

    /// エクササイズの進捗に基づいて重量増加を提案
    func suggestWeightIncrease(
        for exerciseName: String,
        sessions: [WorkoutSession]
    ) -> OverloadSuggestion? {
        // 対象エクササイズの完了データを取得
        let relevantExercises = extractRelevantExercises(
            exerciseName: exerciseName,
            from: sessions
        )

        guard !relevantExercises.isEmpty else { return nil }

        // 最新の重量を取得
        guard let latestWeight = getLatestWeight(from: relevantExercises),
              latestWeight > 0 else { return nil }

        // パフォーマンス指標を分析
        let performanceMetrics = analyzePerformance(relevantExercises)

        // 提案を計算
        return calculateSuggestion(
            exerciseName: exerciseName,
            currentWeight: latestWeight,
            metrics: performanceMetrics,
            dataPoints: relevantExercises.count
        )
    }

    /// 複数のエクササイズに対してまとめて提案を生成
    func suggestWeightIncreases(
        for exercises: [Exercise],
        sessions: [WorkoutSession]
    ) -> [OverloadSuggestion] {
        exercises.compactMap { exercise in
            suggestWeightIncrease(for: exercise.name, sessions: sessions)
        }
    }

    // MARK: - Private Methods

    private func extractRelevantExercises(
        exerciseName: String,
        from sessions: [WorkoutSession]
    ) -> [CompletedExercise] {
        // 完了したセッションから対象エクササイズを抽出
        let completedSessions = sessions
            .filter { $0.isCompleted }
            .sorted { $0.startTime > $1.startTime }
            .prefix(minSessionsForAnalysis)

        return completedSessions.flatMap { session in
            session.completedExercises.filter { exercise in
                exercise.exerciseName == exerciseName &&
                exercise.isCompleted &&
                !exercise.actualWeight.isEmpty
            }
        }
    }

    private func getLatestWeight(from exercises: [CompletedExercise]) -> Double? {
        exercises.first?.averageWeight
    }

    private func analyzePerformance(_ exercises: [CompletedExercise]) -> PerformanceMetrics {
        guard !exercises.isEmpty else {
            return PerformanceMetrics(
                averageCompletionRate: 0,
                consistentFormQuality: false,
                progressingVolume: false
            )
        }

        // 完了率の平均
        let avgCompletionRate = exercises.reduce(0.0) { $0 + $1.completionRate } / Double(exercises.count)

        // フォーム品質の一貫性
        let formQualities = exercises.compactMap { $0.formQuality }
        let consistentForm = formQualities.count >= 2 &&
            formQualities.allSatisfy { quality in
                quality == .good || quality == .excellent
            }

        // ボリュームの進捗
        let volumes = exercises.compactMap { $0.totalVolume }
        let progressingVolume = volumes.count >= 2 &&
            volumes.last! >= volumes.first!

        return PerformanceMetrics(
            averageCompletionRate: avgCompletionRate,
            consistentFormQuality: consistentForm,
            progressingVolume: progressingVolume
        )
    }

    private func calculateSuggestion(
        exerciseName: String,
        currentWeight: Double,
        metrics: PerformanceMetrics,
        dataPoints: Int
    ) -> OverloadSuggestion {
        // データ量に基づいて信頼度を決定
        let confidence: OverloadSuggestion.ConfidenceLevel
        if dataPoints >= minSessionsForAnalysis {
            confidence = .high
        } else if dataPoints >= 2 {
            confidence = .medium
        } else {
            confidence = .low
        }

        // パフォーマンスに基づいて増加率を決定
        let increasePercentage: Double
        let reason: String

        if metrics.averageCompletionRate >= 1.0 &&
           metrics.consistentFormQuality &&
           metrics.progressingVolume {
            // 優秀なパフォーマンス: 標準増加
            increasePercentage = standardIncreasePercentage
            reason = "完了率100%、フォーム良好。次のレベルへ進みましょう"
        } else if metrics.averageCompletionRate >= 0.9 &&
                  metrics.consistentFormQuality {
            // 良好なパフォーマンス: 小幅増加
            increasePercentage = minIncreasePercentage
            reason = "安定したパフォーマンス。徐々に負荷を増やしましょう"
        } else if metrics.averageCompletionRate >= 0.8 {
            // まあまあのパフォーマンス: 最小増加
            increasePercentage = minIncreasePercentage / 2
            reason = "フォームの維持を優先しながら、わずかに負荷を増やしてみましょう"
        } else {
            // 低パフォーマンス: 現状維持
            increasePercentage = 0
            reason = "現在の重量で完了率とフォームの向上に集中しましょう"
        }

        let suggestedWeight = currentWeight * (1 + increasePercentage)

        // 2.5kg単位に丸める（一般的なプレート重量）
        let roundedWeight = round(suggestedWeight / 2.5) * 2.5

        return OverloadSuggestion(
            exerciseName: exerciseName,
            currentWeight: currentWeight,
            suggestedWeight: max(roundedWeight, currentWeight),
            increasePercentage: increasePercentage * 100,
            reason: reason,
            confidence: confidence
        )
    }
}

// MARK: - Supporting Types

private struct PerformanceMetrics {
    let averageCompletionRate: Double
    let consistentFormQuality: Bool
    let progressingVolume: Bool
}
