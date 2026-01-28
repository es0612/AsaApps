import Foundation

/// AI学習最適化エンジン
/// 6要因重み付けアルゴリズムで学習項目の優先順序を最適化
final class StudyOptimizer {

    // MARK: - Properties

    private let featureExtractor: LearningFeatureExtractor
    private let spacedRepetitionEngine: SpacedRepetitionEngine
    private var weights: OptimizationWeights

    // MARK: - Initializer

    init(
        weights: OptimizationWeights = .default,
        featureExtractor: LearningFeatureExtractor = LearningFeatureExtractor(),
        spacedRepetitionEngine: SpacedRepetitionEngine = SpacedRepetitionEngine()
    ) {
        self.weights = weights
        self.featureExtractor = featureExtractor
        self.spacedRepetitionEngine = spacedRepetitionEngine
    }

    // MARK: - Weight Management

    /// 重みを更新
    func updateWeights(_ newWeights: OptimizationWeights) {
        weights = newWeights
    }

    /// 現在の重みを取得
    func currentWeights() -> OptimizationWeights {
        weights
    }

    // MARK: - Priority Calculation

    /// 単一項目の優先度を計算
    func calculatePriority(for item: StudyItem, at currentTime: Date = Date()) -> ItemPriorityResult {
        let features = featureExtractor.extractFeatures(from: item, at: currentTime)

        // 6要因の重み付けスコア計算
        let targetDateComponent = features.targetDateScore * weights.targetDateWeight
        let difficultyTimeComponent = features.difficultyTimeScore * weights.difficultyTimeWeight
        let masteryComponent = features.masteryScore * weights.masteryWeight
        let reviewComponent = features.reviewScore * weights.reviewWeight
        let timeOfDayComponent = features.timeOfDayScore * weights.timeOfDayWeight
        let prerequisiteComponent = features.prerequisiteScore * weights.prerequisiteWeight

        let totalScore = targetDateComponent + difficultyTimeComponent + masteryComponent +
                         reviewComponent + timeOfDayComponent + prerequisiteComponent

        // スコアを0.0-1.0に正規化
        let normalizedScore = min(max(totalScore, 0.0), 1.0)

        // 理由を生成
        let reasons = generateReasons(
            item: item,
            features: features,
            componentScores: ItemPriorityResult.ComponentScores(
                targetDateScore: targetDateComponent,
                difficultyTimeScore: difficultyTimeComponent,
                masteryScore: masteryComponent,
                reviewScore: reviewComponent,
                timeOfDayScore: timeOfDayComponent,
                prerequisiteScore: prerequisiteComponent
            )
        )

        return ItemPriorityResult(
            itemId: item.id,
            totalScore: normalizedScore,
            componentScores: ItemPriorityResult.ComponentScores(
                targetDateScore: targetDateComponent,
                difficultyTimeScore: difficultyTimeComponent,
                masteryScore: masteryComponent,
                reviewScore: reviewComponent,
                timeOfDayScore: timeOfDayComponent,
                prerequisiteScore: prerequisiteComponent
            ),
            reasons: reasons
        )
    }

    /// 複数項目を最適化された順序でソート
    func optimizeStudyOrder(
        items: [StudyItem],
        at currentTime: Date = Date()
    ) -> OptimizationResult {
        guard !items.isEmpty else {
            return .empty
        }

        // 各項目の優先度を計算
        var priorityResults: [ItemPriorityResult] = []
        var priorityScores: [UUID: Double] = [:]

        for item in items {
            let result = calculatePriority(for: item, at: currentTime)
            priorityResults.append(result)
            priorityScores[item.id] = result.totalScore
        }

        // スコアの降順でソート
        let sortedResults = priorityResults.sorted { $0.totalScore > $1.totalScore }
        let orderedItemIds = sortedResults.map(\.itemId)

        // 全体の最適化スコアと信頼度を計算
        let overallScore = calculateOverallScore(priorityResults)
        let confidenceScore = calculateConfidenceScore(items: items, results: priorityResults)

        // 最適化理由を生成
        let reasons = generateOptimizationReasons(
            topResults: Array(sortedResults.prefix(3)),
            items: items
        )

        return OptimizationResult(
            orderedItemIds: orderedItemIds,
            priorityScores: priorityScores,
            reasons: reasons,
            overallScore: overallScore,
            confidenceScore: confidenceScore,
            weightsUsed: weights
        )
    }

    // MARK: - Reason Generation

    /// 個別項目の優先度理由を生成
    private func generateReasons(
        item: StudyItem,
        features: LearningFeatures,
        componentScores: ItemPriorityResult.ComponentScores
    ) -> [String] {
        var reasons: [String] = []

        // 最も影響が大きい要因を特定
        let components = [
            ("targetDate", componentScores.targetDateScore, features.targetDateScore),
            ("difficultyTime", componentScores.difficultyTimeScore, features.difficultyTimeScore),
            ("mastery", componentScores.masteryScore, features.masteryScore),
            ("review", componentScores.reviewScore, features.reviewScore),
            ("timeOfDay", componentScores.timeOfDayScore, features.timeOfDayScore),
            ("prerequisite", componentScores.prerequisiteScore, features.prerequisiteScore)
        ]

        let sorted = components.sorted { $0.1 > $1.1 }

        // 上位3要因の理由を生成
        for (type, _, rawScore) in sorted.prefix(3) {
            if let reason = generateReasonText(type: type, rawScore: rawScore, item: item) {
                reasons.append(reason)
            }
        }

        return reasons
    }

    private func generateReasonText(type: String, rawScore: Double, item: StudyItem) -> String? {
        guard rawScore > 0.3 else { return nil }  // 低スコアは理由として表示しない

        switch type {
        case "targetDate":
            if let days = item.daysUntilTarget {
                if days < 0 {
                    return "📅 期限が\(-days)日過ぎています"
                } else if days == 0 {
                    return "📅 今日が期限です"
                } else if days <= 3 {
                    return "📅 期限まであと\(days)日です"
                } else if days <= 7 {
                    return "📅 1週間以内に期限があります"
                }
            }
            return nil

        case "difficultyTime":
            let hour = Calendar.current.component(.hour, from: Date())
            if hour >= 5 && hour < 9 && item.difficulty == .hard || item.difficulty == .expert {
                return "🌅 朝の集中力を活かせる難しい内容です"
            } else if rawScore > 0.6 {
                return "⏰ 今の時間帯に適した難易度です"
            }
            return nil

        case "mastery":
            if item.masteryLevel < 0.3 {
                return "📚 まだ習熟度が低いので優先的に学習しましょう"
            } else if item.masteryLevel < 0.6 {
                return "📖 中級レベルに向けて学習を続けましょう"
            }
            return nil

        case "review":
            if item.needsReview {
                return "🔄 復習のタイミングです"
            } else if rawScore > 0.5 {
                return "📝 復習で定着を図りましょう"
            }
            return nil

        case "timeOfDay":
            let hour = Calendar.current.component(.hour, from: Date())
            if hour >= 5 && hour < 7 {
                return "☀️ 朝活のゴールデンタイムです"
            } else if hour >= 7 && hour < 9 {
                return "🌤 朝の集中しやすい時間帯です"
            }
            return nil

        case "prerequisite":
            if item.prerequisiteItemIds.isEmpty && rawScore > 0.8 {
                return "✅ 前提知識なしですぐに始められます"
            }
            return nil

        default:
            return nil
        }
    }

    /// 全体最適化の理由を生成
    private func generateOptimizationReasons(
        topResults: [ItemPriorityResult],
        items: [StudyItem]
    ) -> [String] {
        var reasons: [String] = []

        // 最優先項目の理由
        if let top = topResults.first,
           let topItem = items.first(where: { $0.id == top.itemId }) {
            reasons.append("🎯 「\(topItem.title)」を最優先で学習することを推奨します")
        }

        // 復習が必要な項目数
        let reviewCount = items.filter(\.needsReview).count
        if reviewCount > 0 {
            reasons.append("🔄 \(reviewCount)件の復習が必要な項目があります")
        }

        // 期限が近い項目
        let urgentCount = items.filter { ($0.daysUntilTarget ?? 100) <= 3 }.count
        if urgentCount > 0 {
            reasons.append("⚠️ \(urgentCount)件の期限が迫っている項目があります")
        }

        // 朝活時間帯の場合
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 5 && hour < 7 {
            reasons.append("🌅 朝活ゴールデンタイム！難しい内容に挑戦しましょう")
        }

        return reasons
    }

    // MARK: - Score Calculation

    /// 全体の最適化スコアを計算
    private func calculateOverallScore(_ results: [ItemPriorityResult]) -> Double {
        guard !results.isEmpty else { return 0.0 }

        // 平均スコア
        let averageScore = results.reduce(0.0) { $0 + $1.totalScore } / Double(results.count)

        // スコアの分散（分散が小さいほど良い最適化）
        let variance = results.reduce(0.0) { sum, result in
            sum + pow(result.totalScore - averageScore, 2)
        } / Double(results.count)

        // 分散が小さいほど高スコア
        let varianceBonus = max(0.0, 0.2 - variance)

        return min(averageScore + varianceBonus, 1.0)
    }

    /// 信頼度スコアを計算
    private func calculateConfidenceScore(
        items: [StudyItem],
        results: [ItemPriorityResult]
    ) -> Double {
        guard !items.isEmpty else { return 0.0 }

        var confidence = 0.5  // ベース信頼度

        // データが豊富なほど信頼度が上がる
        let averageSessionCount = Double(items.reduce(0) { $0 + $1.sessionCount }) / Double(items.count)
        confidence += min(averageSessionCount * 0.05, 0.2)

        // 期限が設定されている項目が多いほど信頼度が上がる
        let itemsWithDeadline = items.filter { $0.targetDate != nil }.count
        let deadlineRatio = Double(itemsWithDeadline) / Double(items.count)
        confidence += deadlineRatio * 0.15

        // スコアの差が明確なほど信頼度が上がる
        if results.count >= 2 {
            let scoreDiff = (results.first?.totalScore ?? 0) - (results.last?.totalScore ?? 0)
            confidence += min(scoreDiff * 0.2, 0.15)
        }

        return min(confidence, 0.95)
    }

    // MARK: - Item Update

    /// 最適化結果を学習項目に適用
    func applyOptimizationToItems(_ items: [StudyItem], result: OptimizationResult) {
        for item in items {
            if let score = result.priorityScores[item.id] {
                let itemResult = calculatePriority(for: item)
                item.applyAIPrediction(
                    score: score,
                    confidence: result.confidenceScore,
                    reasons: itemResult.reasons
                )
            }
        }
    }
}

// MARK: - Convenience Extensions

extension StudyOptimizer {

    /// 朝活に最適な項目を取得
    func getOptimalMorningItems(_ items: [StudyItem], limit: Int = 3) -> [StudyItem] {
        // 朝活重視モードで最適化
        let morningOptimizer = StudyOptimizer(weights: .morningFocused)
        let result = morningOptimizer.optimizeStudyOrder(items: items)

        return result.orderedItemIds.prefix(limit).compactMap { id in
            items.first { $0.id == id }
        }
    }

    /// 復習優先の項目を取得
    func getReviewPriorityItems(_ items: [StudyItem], limit: Int = 5) -> [StudyItem] {
        let reviewOptimizer = StudyOptimizer(weights: .reviewFocused)
        let result = reviewOptimizer.optimizeStudyOrder(items: items)

        return result.orderedItemIds.prefix(limit).compactMap { id in
            items.first { $0.id == id }
        }
    }

    /// 期限優先の項目を取得
    func getDeadlinePriorityItems(_ items: [StudyItem], limit: Int = 5) -> [StudyItem] {
        let deadlineOptimizer = StudyOptimizer(weights: .deadlineFocused)
        let result = deadlineOptimizer.optimizeStudyOrder(items: items)

        return result.orderedItemIds.prefix(limit).compactMap { id in
            items.first { $0.id == id }
        }
    }
}
