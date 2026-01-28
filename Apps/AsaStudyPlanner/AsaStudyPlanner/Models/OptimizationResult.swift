import Foundation

/// AI最適化の結果を表す構造体
struct OptimizationResult: Sendable, Equatable {
    /// 最適化された学習項目ID（優先順）
    let orderedItemIds: [UUID]

    /// 各項目の優先度スコア
    let priorityScores: [UUID: Double]

    /// 最適化理由
    let reasons: [String]

    /// 全体の最適化スコア（0.0-1.0）
    let overallScore: Double

    /// 信頼度スコア（0.0-1.0）
    let confidenceScore: Double

    /// 最適化に使用された重み
    let weightsUsed: OptimizationWeights

    /// 最適化実行時刻
    let generatedAt: Date

    init(
        orderedItemIds: [UUID],
        priorityScores: [UUID: Double],
        reasons: [String],
        overallScore: Double,
        confidenceScore: Double,
        weightsUsed: OptimizationWeights,
        generatedAt: Date = Date()
    ) {
        self.orderedItemIds = orderedItemIds
        self.priorityScores = priorityScores
        self.reasons = reasons
        self.overallScore = overallScore
        self.confidenceScore = confidenceScore
        self.weightsUsed = weightsUsed
        self.generatedAt = generatedAt
    }

    /// 空の結果
    static var empty: OptimizationResult {
        OptimizationResult(
            orderedItemIds: [],
            priorityScores: [:],
            reasons: [],
            overallScore: 0.0,
            confidenceScore: 0.0,
            weightsUsed: .default
        )
    }
}

/// 最適化に使用する重み設定
struct OptimizationWeights: Sendable, Equatable, Codable {
    /// 目標期限の重み（デフォルト35%）
    let targetDateWeight: Double

    /// 難易度×時間帯の重み（デフォルト20%）
    let difficultyTimeWeight: Double

    /// 習熟度の重み（デフォルト15%）
    let masteryWeight: Double

    /// 復習必要度の重み（デフォルト10%）
    let reviewWeight: Double

    /// 時間帯適性の重み（デフォルト10%）
    let timeOfDayWeight: Double

    /// 前提知識の重み（デフォルト10%）
    let prerequisiteWeight: Double

    /// デフォルト重み
    static let `default` = OptimizationWeights(
        targetDateWeight: 0.35,
        difficultyTimeWeight: 0.20,
        masteryWeight: 0.15,
        reviewWeight: 0.10,
        timeOfDayWeight: 0.10,
        prerequisiteWeight: 0.10
    )

    /// 期限重視モード
    static let deadlineFocused = OptimizationWeights(
        targetDateWeight: 0.50,
        difficultyTimeWeight: 0.15,
        masteryWeight: 0.10,
        reviewWeight: 0.10,
        timeOfDayWeight: 0.10,
        prerequisiteWeight: 0.05
    )

    /// 朝活重視モード
    static let morningFocused = OptimizationWeights(
        targetDateWeight: 0.25,
        difficultyTimeWeight: 0.30,
        masteryWeight: 0.10,
        reviewWeight: 0.10,
        timeOfDayWeight: 0.20,
        prerequisiteWeight: 0.05
    )

    /// 復習重視モード
    static let reviewFocused = OptimizationWeights(
        targetDateWeight: 0.20,
        difficultyTimeWeight: 0.15,
        masteryWeight: 0.15,
        reviewWeight: 0.30,
        timeOfDayWeight: 0.10,
        prerequisiteWeight: 0.10
    )

    /// 重みの合計が1.0であることを検証
    var isValid: Bool {
        let total = targetDateWeight + difficultyTimeWeight + masteryWeight +
                    reviewWeight + timeOfDayWeight + prerequisiteWeight
        return abs(total - 1.0) < 0.001
    }

    /// カスタム重みの作成
    init(
        targetDateWeight: Double,
        difficultyTimeWeight: Double,
        masteryWeight: Double,
        reviewWeight: Double,
        timeOfDayWeight: Double,
        prerequisiteWeight: Double
    ) {
        self.targetDateWeight = targetDateWeight
        self.difficultyTimeWeight = difficultyTimeWeight
        self.masteryWeight = masteryWeight
        self.reviewWeight = reviewWeight
        self.timeOfDayWeight = timeOfDayWeight
        self.prerequisiteWeight = prerequisiteWeight
    }
}

/// 単一項目の優先度計算結果
struct ItemPriorityResult: Sendable {
    let itemId: UUID
    let totalScore: Double
    let componentScores: ComponentScores
    let reasons: [String]

    struct ComponentScores: Sendable {
        let targetDateScore: Double
        let difficultyTimeScore: Double
        let masteryScore: Double
        let reviewScore: Double
        let timeOfDayScore: Double
        let prerequisiteScore: Double

        var asArray: [Double] {
            [targetDateScore, difficultyTimeScore, masteryScore,
             reviewScore, timeOfDayScore, prerequisiteScore]
        }
    }
}
