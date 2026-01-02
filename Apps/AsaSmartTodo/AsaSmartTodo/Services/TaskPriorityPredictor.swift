//
//  TaskPriorityPredictor.swift
//  AsaSmartTodo
//
//  AI優先度予測エンジン
//  6要因の重み付け計算でタスクの優先度を予測
//

import Foundation

/// 優先度予測の重み設定
struct PriorityWeights {
    let dueDateWeight: Double           // 期限（35%）
    let categoryWeight: Double          // カテゴリ（20%）
    let titleComplexityWeight: Double   // タイトル複雑度（15%）
    let descriptionWeight: Double       // 説明詳細度（10%）
    let timeOfDayWeight: Double         // 朝活時間帯（10%）
    let historicalWeight: Double        // 履歴完了率（10%）

    static let `default` = PriorityWeights(
        dueDateWeight: 0.35,
        categoryWeight: 0.20,
        titleComplexityWeight: 0.15,
        descriptionWeight: 0.10,
        timeOfDayWeight: 0.10,
        historicalWeight: 0.10
    )
}

/// AI優先度予測エンジン
final class TaskPriorityPredictor {
    private var weights: PriorityWeights
    private let featureExtractor: TaskFeatureExtractor

    init(weights: PriorityWeights = .default) {
        self.weights = weights
        self.featureExtractor = TaskFeatureExtractor()
    }

    /// 重みを更新（設定変更時に呼ばれる）
    func updateWeights(_ newWeights: PriorityWeights) {
        self.weights = newWeights
    }

    /// タスクの優先度を予測
    func predictPriority(for task: SmartTask) -> PredictionResult {
        // 特徴量を抽出
        let features = featureExtractor.extractFeatures(from: task)

        var totalScore: Double = 0.0
        var reasons: [PredictionReason] = []

        // 1. 期限スコア（35%）
        let dueDateScore = features.dueDateScore * weights.dueDateWeight
        totalScore += dueDateScore

        if let days = features.daysUntilDue, days <= 1 {
            reasons.append(.dueDateUrgent(days))
        }

        // 2. カテゴリスコア（20%）
        let categoryScore = features.categoryImportanceScore * weights.categoryWeight
        totalScore += categoryScore

        if features.categoryImportanceScore >= 0.7 {
            reasons.append(.categoryImportant(task.category))
        }

        // 3. タイトル複雑度スコア（15%）
        let titleScore = features.titleComplexity * weights.titleComplexityWeight
        totalScore += titleScore

        if features.titleComplexity >= 0.6 {
            let wordCount = task.title.split(separator: " ").count
            reasons.append(.complexTitle(wordCount))
        }

        // 4. 説明文スコア（10%）
        let descriptionScore = features.descriptionComplexity * weights.descriptionWeight
        totalScore += descriptionScore

        if features.descriptionComplexity >= 0.5, let desc = task.taskDescription {
            reasons.append(.detailedDescription(desc.count))
        }

        // 5. 時間帯スコア（10%）朝活ボーナス
        let timeScore = features.timeOfDayScore * weights.timeOfDayWeight
        totalScore += timeScore

        if features.createdHour >= 5 && features.createdHour < 7 {
            reasons.append(.morningBoost())
        }

        // 6. 履歴完了率スコア（10%）
        // TODO: 将来のCore ML実装で追加
        // 現在は0.5（中立）を仮定
        let historicalScore = 0.5 * weights.historicalWeight
        totalScore += historicalScore

        // スコアを0.0-1.0の範囲に正規化
        let normalizedScore = min(max(totalScore, 0.0), 1.0)

        // スコアから優先度と信頼度を決定
        let (priority, confidence) = convertScoreToPriority(normalizedScore)

        return PredictionResult(
            suggestedPriority: priority,
            confidenceScore: confidence,
            reasons: reasons
        )
    }

    /// スコアを優先度と信頼度に変換
    private func convertScoreToPriority(_ score: Double) -> (PriorityLevel, Double) {
        let priority: PriorityLevel
        let confidence: Double

        if score >= 0.7 {
            // 高優先度
            priority = .high
            confidence = min(score, 0.95)  // 最大95%
        } else if score >= 0.4 {
            // 中優先度
            priority = .medium
            confidence = 0.7 + (score - 0.4) * 0.5  // 0.7-0.85の範囲
        } else {
            // 低優先度
            priority = .low
            confidence = 0.5 + score * 0.5  // 0.5-0.7の範囲
        }

        return (priority, confidence)
    }

    /// リアルタイム予測（タスク入力中）
    /// SmartTaskオブジェクトなしで予測を実行
    func predictPriorityRealtime(
        title: String,
        description: String?,
        category: TaskCategory,
        dueDate: Date?
    ) -> PredictionResult {
        // 一時的なSmartTaskオブジェクトを作成
        let tempTask = SmartTask(
            title: title,
            description: description,
            category: category,
            userPriority: .medium,
            dueDate: dueDate
        )

        // 特徴量を計算
        let titleComplexity = featureExtractor.calculateTitleComplexity(title)
        let descriptionComplexity = featureExtractor.calculateDescriptionComplexity(description)

        tempTask.titleComplexity = titleComplexity
        tempTask.descriptionComplexity = descriptionComplexity

        // 予測を実行
        return predictPriority(for: tempTask)
    }
}
