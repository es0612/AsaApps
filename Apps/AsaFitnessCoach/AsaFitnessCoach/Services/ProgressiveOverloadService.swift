//
//  ProgressiveOverloadService.swift
//  AsaFitnessCoach
//
//  プログレッシブ・オーバーロード計算サービス
//  過去のパフォーマンスに基づいて重量増加を提案
//

import Foundation

/// プログレッシブ・オーバーロード計算サービス
final class ProgressiveOverloadService {
    // MARK: - Properties

    private let minIncreasePercentage = 0.025  // 2.5%
    private let standardIncreasePercentage = 0.05  // 5%
    private let maxIncreasePercentage = 0.10  // 10%
    private let minSessionsForHighConfidence = 3

    // MARK: - Public Methods

    /// エクササイズの進捗に基づいて重量増加を提案
    func suggestWeightIncrease(
        for exerciseName: String,
        sessions: [WorkoutSession]
    ) -> ProgressiveOverloadSuggestion? {
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
    ) -> [ProgressiveOverloadSuggestion] {
        exercises.compactMap { exercise in
            suggestWeightIncrease(for: exercise.name, sessions: sessions)
        }
    }

    /// すべてのエクササイズ名に対して提案を生成
    func suggestAllWeightIncreases(
        sessions: [WorkoutSession]
    ) -> [ProgressiveOverloadSuggestion] {
        // 完了したセッションからユニークなエクササイズ名を取得
        let exerciseNames = Set(
            sessions.flatMap { $0.completedExercises.map { $0.exerciseName } }
        )

        return exerciseNames.compactMap { name in
            suggestWeightIncrease(for: name, sessions: sessions)
        }.sorted { $0.increasePercentage > $1.increasePercentage }
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

        return completedSessions.flatMap { session in
            session.completedExercises.filter { exercise in
                exercise.exerciseName == exerciseName &&
                exercise.isCompleted &&
                !exercise.actualWeight.isEmpty &&
                exercise.actualWeight.contains { $0 > 0 }
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
                progressingVolume: false,
                improvementTrend: .stable
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
        let progressingVolume = volumes.count >= 2 && (volumes.last ?? 0) >= (volumes.first ?? 0)

        // 改善トレンド
        let trend = calculateImprovementTrend(volumes: volumes)

        return PerformanceMetrics(
            averageCompletionRate: avgCompletionRate,
            consistentFormQuality: consistentForm,
            progressingVolume: progressingVolume,
            improvementTrend: trend
        )
    }

    private func calculateImprovementTrend(volumes: [Double]) -> ImprovementTrend {
        guard volumes.count >= 3 else { return .stable }

        let recentVolumes = Array(volumes.prefix(3))
        let averageChange = zip(recentVolumes.dropFirst(), recentVolumes).map { $0 - $1 }.reduce(0, +) / Double(recentVolumes.count - 1)

        if averageChange > 0 {
            return .improving
        } else if averageChange < 0 {
            return .declining
        } else {
            return .stable
        }
    }

    private func calculateSuggestion(
        exerciseName: String,
        currentWeight: Double,
        metrics: PerformanceMetrics,
        dataPoints: Int
    ) -> ProgressiveOverloadSuggestion {
        // データ量に基づいて信頼度を決定
        let confidence: ProgressiveOverloadSuggestion.ConfidenceLevel
        if dataPoints >= minSessionsForHighConfidence {
            confidence = .high
        } else if dataPoints >= 2 {
            confidence = .medium
        } else {
            confidence = .low
        }

        // パフォーマンスに基づいて増加率を決定
        let increasePercentage: Double
        let reason: String

        switch (metrics.averageCompletionRate, metrics.consistentFormQuality, metrics.improvementTrend) {
        case (0.95..., true, .improving):
            // 優秀なパフォーマンス + 改善中: 標準増加
            increasePercentage = standardIncreasePercentage
            reason = "完了率95%以上、フォーム良好、ボリューム増加中。次のレベルへ進みましょう！"

        case (0.95..., true, _):
            // 優秀なパフォーマンス: 標準増加
            increasePercentage = standardIncreasePercentage
            reason = "完了率95%以上、フォーム良好。負荷を増やす準備ができています"

        case (0.9..., true, _):
            // 良好なパフォーマンス: 小幅増加
            increasePercentage = minIncreasePercentage
            reason = "安定したパフォーマンス。徐々に負荷を増やしましょう"

        case (0.85..., _, .improving):
            // まあまあのパフォーマンス + 改善中: 最小増加
            increasePercentage = minIncreasePercentage
            reason = "改善傾向が見られます。フォームを維持しながら負荷を増やしてみましょう"

        case (0.8..., _, _):
            // まあまあのパフォーマンス: 最小増加
            increasePercentage = minIncreasePercentage / 2
            reason = "フォームの維持を優先しながら、わずかに負荷を増やしてみましょう"

        case (_, _, .declining):
            // パフォーマンス低下中: 現状維持
            increasePercentage = 0
            reason = "パフォーマンスが低下傾向です。現在の重量で安定させましょう"

        default:
            // 低パフォーマンス: 現状維持
            increasePercentage = 0
            reason = "現在の重量で完了率とフォームの向上に集中しましょう"
        }

        let suggestedWeight = currentWeight * (1 + increasePercentage)

        // 2.5kg単位に丸める（一般的なプレート重量）
        let roundedWeight = round(suggestedWeight / 2.5) * 2.5

        return ProgressiveOverloadSuggestion(
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
    let improvementTrend: ImprovementTrend
}

private enum ImprovementTrend {
    case improving
    case stable
    case declining
}
