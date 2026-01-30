//
//  WorkoutPlanGenerator.swift
//  AsaFitnessCoach
//
//  AI運動プラン生成サービス（6要因重み付けスコアリング）
//

import Foundation

/// AI運動プラン生成サービス
/// 6要因の重み付けスコアリングでユーザーに最適なプランを提案
@MainActor
final class WorkoutPlanGenerator {
    // MARK: - Properties

    /// 6要因の重み
    var weights: PlanWeights = .default

    // MARK: - Public Methods

    /// ユーザープロファイルに基づいてAI運動プランを生成
    func generatePlan(
        for profile: UserProfile,
        recentSessions: [WorkoutSession] = [],
        existingPlans: [WorkoutPlan] = []
    ) -> AIRecommendation {
        // 1. 利用可能なエクササイズをフィルタリング
        let availableExercises = filterExercises(for: profile)

        // 2. 各エクササイズのスコアを計算
        let scoredExercises = availableExercises.map { exercise -> (PresetExercise, Double, [RecommendationReason]) in
            let (score, reasons) = calculateExerciseScore(
                exercise: exercise,
                profile: profile,
                recentSessions: recentSessions
            )
            return (exercise, score, reasons)
        }

        // 3. 上位のエクササイズを選択
        let selectedExercises = selectTopExercises(
            from: scoredExercises,
            targetDuration: profile.preferredWorkoutDuration,
            profile: profile
        )

        // 4. カテゴリと難易度を決定
        let category = determineCategory(for: profile)
        let difficulty = determineDifficulty(for: profile)

        // 5. 提案理由を集約
        let aggregatedReasons = aggregateReasons(from: selectedExercises.map { $0.2 })

        // 6. 信頼度を計算
        let confidence = calculateConfidence(
            scores: selectedExercises.map { $0.1 },
            dataPoints: recentSessions.count
        )

        // 7. 推定時間を計算
        let estimatedDuration = calculateEstimatedDuration(
            exercises: selectedExercises.map { $0.0 }
        )

        // 8. 結果を構築
        return AIRecommendation(
            planName: generatePlanName(category: category, profile: profile),
            planDescription: generatePlanDescription(profile: profile, category: category),
            exercises: selectedExercises.map { exercise, score, _ in
                createRecommendedExercise(from: exercise, matchScore: score, profile: profile)
            },
            category: category,
            difficulty: difficulty,
            estimatedDuration: estimatedDuration,
            confidence: confidence,
            reasons: aggregatedReasons
        )
    }

    // MARK: - 6要因スコアリング

    /// エクササイズのスコアを計算（6要因）
    private func calculateExerciseScore(
        exercise: PresetExercise,
        profile: UserProfile,
        recentSessions: [WorkoutSession]
    ) -> (Double, [RecommendationReason]) {
        let normalizedWeights = weights.normalized()
        var reasons: [RecommendationReason] = []
        var totalScore: Double = 0

        // 1. 目標適合度
        let goalScore = calculateGoalAlignmentScore(exercise: exercise, goal: profile.primaryGoal)
        totalScore += goalScore * normalizedWeights.goalAlignment
        reasons.append(RecommendationReason(
            factor: .goalAlignment,
            score: goalScore,
            explanation: getGoalAlignmentExplanation(score: goalScore, goal: profile.primaryGoal)
        ))

        // 2. 体力レベル適合
        let fitnessScore = calculateFitnessLevelScore(exercise: exercise, level: profile.fitnessLevel)
        totalScore += fitnessScore * normalizedWeights.fitnessLevel
        reasons.append(RecommendationReason(
            factor: .fitnessLevel,
            score: fitnessScore,
            explanation: getFitnessLevelExplanation(score: fitnessScore, level: profile.fitnessLevel)
        ))

        // 3. 機器適合
        let equipmentScore = calculateEquipmentMatchScore(exercise: exercise, available: profile.availableEquipment)
        totalScore += equipmentScore * normalizedWeights.equipmentMatch
        reasons.append(RecommendationReason(
            factor: .equipmentMatch,
            score: equipmentScore,
            explanation: getEquipmentMatchExplanation(score: equipmentScore)
        ))

        // 4. 時間制約
        let timeScore = calculateTimeConstraintScore(exercise: exercise, targetDuration: profile.preferredWorkoutDuration)
        totalScore += timeScore * normalizedWeights.timeConstraint
        reasons.append(RecommendationReason(
            factor: .timeConstraint,
            score: timeScore,
            explanation: getTimeConstraintExplanation(score: timeScore, targetDuration: profile.preferredWorkoutDuration)
        ))

        // 5. 回復状態
        let recoveryScore = calculateRecoveryScore(exercise: exercise, recentSessions: recentSessions)
        totalScore += recoveryScore * normalizedWeights.recoveryStatus
        reasons.append(RecommendationReason(
            factor: .recoveryStatus,
            score: recoveryScore,
            explanation: getRecoveryExplanation(score: recoveryScore)
        ))

        // 6. 進捗ペース
        let progressionScore = calculateProgressionScore(exercise: exercise, recentSessions: recentSessions)
        totalScore += progressionScore * normalizedWeights.progressionRate
        reasons.append(RecommendationReason(
            factor: .progressionRate,
            score: progressionScore,
            explanation: getProgressionExplanation(score: progressionScore)
        ))

        return (totalScore, reasons)
    }

    // MARK: - 各要因のスコア計算

    /// 1. 目標適合度
    private func calculateGoalAlignmentScore(exercise: PresetExercise, goal: FitnessGoalType) -> Double {
        let recommendedCategories = goal.recommendedCategories

        // エクササイズのカテゴリがゴールに推奨されているか
        let categoryMatch = recommendedCategories.contains { recommended in
            switch (recommended, exercise.category) {
            case (.strength, .chest), (.strength, .back), (.strength, .legs),
                 (.strength, .shoulders), (.strength, .arms):
                return true
            case (.cardio, .cardio):
                return true
            case (.bodyweight, .core), (.bodyweight, .compound), (.bodyweight, .fullBody):
                return true
            case (.yoga, .flexibility), (.stretching, .flexibility):
                return true
            case (.hiit, .cardio), (.hiit, .fullBody):
                return true
            default:
                return false
            }
        }

        if categoryMatch {
            return 0.9 + Double.random(in: 0...0.1)
        }

        // 部分的なマッチ
        let generalMatch = exercise.category == .fullBody || exercise.category == .compound
        return generalMatch ? 0.6 : 0.3
    }

    /// 2. 体力レベル適合
    private func calculateFitnessLevelScore(exercise: PresetExercise, level: FitnessLevel) -> Double {
        let exerciseDifficulty = exercise.difficulty.numericValue
        let userLevel = level == .beginner ? 1 : level == .intermediate ? 2 : level == .advanced ? 3 : 4

        let difference = abs(exerciseDifficulty - userLevel)

        switch difference {
        case 0:
            return 1.0  // 完璧なマッチ
        case 1:
            return exerciseDifficulty < userLevel ? 0.8 : 0.7  // 少し簡単/難しい
        default:
            return exerciseDifficulty < userLevel ? 0.5 : 0.3  // かなり簡単/難しい
        }
    }

    /// 3. 機器適合
    private func calculateEquipmentMatchScore(exercise: PresetExercise, available: [Equipment]) -> Double {
        // 器具不要のエクササイズ
        if exercise.requiredEquipment.isEmpty || exercise.requiredEquipment == [.none] {
            return 1.0
        }

        // 利用可能な器具がない場合
        if available.isEmpty {
            return exercise.requiredEquipment == [.none] ? 1.0 : 0.0
        }

        // 必要な器具がすべて利用可能か
        let allAvailable = exercise.requiredEquipment.allSatisfy { equipment in
            equipment == .none || available.contains(equipment)
        }

        if allAvailable {
            return 1.0
        }

        // 部分的に利用可能
        let availableCount = exercise.requiredEquipment.filter { equipment in
            equipment == .none || available.contains(equipment)
        }.count

        return Double(availableCount) / Double(exercise.requiredEquipment.count)
    }

    /// 4. 時間制約
    private func calculateTimeConstraintScore(exercise: PresetExercise, targetDuration: Int) -> Double {
        let exerciseDuration = calculateExerciseDuration(exercise)
        let targetSeconds = Double(targetDuration * 60)

        // エクササイズ時間が目標の10%以内なら最高スコア
        if exerciseDuration <= targetSeconds * 0.15 {
            return 1.0
        } else if exerciseDuration <= targetSeconds * 0.25 {
            return 0.8
        } else if exerciseDuration <= targetSeconds * 0.4 {
            return 0.6
        } else {
            return 0.3
        }
    }

    /// 5. 回復状態
    private func calculateRecoveryScore(exercise: PresetExercise, recentSessions: [WorkoutSession]) -> Double {
        guard !recentSessions.isEmpty else {
            return 0.8  // データがない場合は中程度のスコア
        }

        // 最近のセッションで使用した筋肉グループを確認
        let recentMuscles = extractRecentlyTrainedMuscles(from: recentSessions)

        // このエクササイズのターゲット筋肉が十分に回復しているか
        let targetMuscles = exercise.targetMuscles
        var totalRecoveryScore: Double = 0

        for muscle in targetMuscles {
            if let lastTrainedDate = recentMuscles[muscle] {
                let hoursSinceTraining = Date().timeIntervalSince(lastTrainedDate) / 3600
                let recoveryTime = Double(muscle.recoveryTime)

                if hoursSinceTraining >= recoveryTime {
                    totalRecoveryScore += 1.0  // 完全回復
                } else if hoursSinceTraining >= recoveryTime * 0.75 {
                    totalRecoveryScore += 0.7  // ほぼ回復
                } else if hoursSinceTraining >= recoveryTime * 0.5 {
                    totalRecoveryScore += 0.4  // 部分的に回復
                } else {
                    totalRecoveryScore += 0.1  // まだ回復中
                }
            } else {
                totalRecoveryScore += 1.0  // 最近トレーニングしていない
            }
        }

        return targetMuscles.isEmpty ? 0.8 : totalRecoveryScore / Double(targetMuscles.count)
    }

    /// 6. 進捗ペース
    private func calculateProgressionScore(exercise: PresetExercise, recentSessions: [WorkoutSession]) -> Double {
        guard recentSessions.count >= 3 else {
            return 0.7  // データ不足の場合は中程度のスコア
        }

        // 最近のセッションでこのエクササイズのパフォーマンスを確認
        let relevantExercises = recentSessions.flatMap { session in
            session.completedExercises.filter { $0.exerciseName == exercise.name }
        }

        guard !relevantExercises.isEmpty else {
            return 0.8  // このエクササイズの履歴がない
        }

        // 完了率をチェック
        let averageCompletionRate = relevantExercises.reduce(0.0) { $0 + $1.completionRate } / Double(relevantExercises.count)

        if averageCompletionRate >= 0.95 {
            return 1.0  // 優秀なパフォーマンス - 負荷増加準備OK
        } else if averageCompletionRate >= 0.85 {
            return 0.8  // 良好
        } else if averageCompletionRate >= 0.7 {
            return 0.6  // まあまあ
        } else {
            return 0.4  // 現在のレベルで継続が必要
        }
    }

    // MARK: - ヘルパーメソッド

    private func filterExercises(for profile: UserProfile) -> [PresetExercise] {
        var exercises = PresetExercises.all

        // 難易度フィルター
        exercises = exercises.filter { exercise in
            Double(exercise.difficulty.numericValue) <= profile.fitnessLevel.difficultyMultiplier * 4.5
        }

        // 器具フィルター（厳密にはスコアリングで対応するが、明らかに不可能なものは除外）
        if profile.availableEquipment.isEmpty {
            exercises = exercises.filter { $0.requiredEquipment.isEmpty || $0.requiredEquipment == [.none] }
        }

        return exercises
    }

    private func selectTopExercises(
        from scoredExercises: [(PresetExercise, Double, [RecommendationReason])],
        targetDuration: Int,
        profile: UserProfile
    ) -> [(PresetExercise, Double, [RecommendationReason])] {
        let sorted = scoredExercises.sorted { $0.1 > $1.1 }

        var selected: [(PresetExercise, Double, [RecommendationReason])] = []
        var totalDuration: Double = 0
        let targetSeconds = Double(targetDuration * 60)
        var usedCategories: Set<ExerciseCategory> = []

        for item in sorted {
            let exerciseDuration = calculateExerciseDuration(item.0)

            // 時間制限チェック
            if totalDuration + exerciseDuration > targetSeconds * 1.1 {
                continue
            }

            // カテゴリの多様性を確保（同じカテゴリは最大2つ）
            let categoryCount = selected.filter { $0.0.category == item.0.category }.count
            if categoryCount >= 2 {
                continue
            }

            selected.append(item)
            totalDuration += exerciseDuration
            usedCategories.insert(item.0.category)

            // 最低4エクササイズ、最大8エクササイズ
            if selected.count >= 8 || (selected.count >= 4 && totalDuration >= targetSeconds * 0.8) {
                break
            }
        }

        return selected
    }

    private func calculateExerciseDuration(_ exercise: PresetExercise) -> Double {
        if let duration = exercise.defaultDuration {
            return (duration * Double(exercise.defaultSets)) + (exercise.defaultRestTime * Double(exercise.defaultSets - 1))
        } else {
            // 1レップ約3秒と仮定
            let exerciseTime = Double(exercise.defaultSets * exercise.defaultReps) * 3.0
            let restTotal = exercise.defaultRestTime * Double(exercise.defaultSets - 1)
            return exerciseTime + restTotal
        }
    }

    private func calculateEstimatedDuration(exercises: [PresetExercise]) -> Int {
        let totalSeconds = exercises.reduce(0.0) { $0 + calculateExerciseDuration($1) }
        return Int(totalSeconds / 60) + 5  // 5分のウォームアップ/クールダウン
    }

    private func extractRecentlyTrainedMuscles(from sessions: [WorkoutSession]) -> [MuscleGroup: Date] {
        var muscleLastTrained: [MuscleGroup: Date] = [:]

        for session in sessions where session.isCompleted {
            for completedExercise in session.completedExercises {
                // プリセットからターゲット筋肉を取得
                if let preset = PresetExercises.all.first(where: { $0.name == completedExercise.exerciseName }) {
                    for muscle in preset.targetMuscles {
                        if muscleLastTrained[muscle] == nil || session.startTime > muscleLastTrained[muscle]! {
                            muscleLastTrained[muscle] = session.startTime
                        }
                    }
                }
            }
        }

        return muscleLastTrained
    }

    private func determineCategory(for profile: UserProfile) -> WorkoutCategory {
        profile.primaryGoal.recommendedCategories.first ?? .general
    }

    private func determineDifficulty(for profile: UserProfile) -> Difficulty {
        switch profile.fitnessLevel {
        case .beginner: return .beginner
        case .intermediate: return .intermediate
        case .advanced: return .advanced
        case .expert: return .expert
        }
    }

    private func generatePlanName(category: WorkoutCategory, profile: UserProfile) -> String {
        let goalName: String
        switch profile.primaryGoal {
        case .muscleGain: goalName = "筋力アップ"
        case .weightLoss: goalName = "脂肪燃焼"
        case .endurance: goalName = "スタミナ向上"
        case .flexibility: goalName = "柔軟性"
        case .generalFitness: goalName = "総合フィットネス"
        case .athleticPerformance: goalName = "パフォーマンス"
        case .rehabilitation: goalName = "リハビリ"
        }
        return "\(goalName)プラン - \(profile.preferredWorkoutDuration)分"
    }

    private func generatePlanDescription(profile: UserProfile, category: WorkoutCategory) -> String {
        "あなたの目標「\(profile.primaryGoal.rawValue)」に最適化された\(profile.preferredWorkoutDuration)分のワークアウトプランです。"
    }

    private func createRecommendedExercise(
        from preset: PresetExercise,
        matchScore: Double,
        profile: UserProfile
    ) -> RecommendedExercise {
        // 体力レベルに応じてセット/レップを調整
        let adjustedSets = adjustSets(preset.defaultSets, for: profile.fitnessLevel)
        let adjustedReps = adjustReps(preset.defaultReps, for: profile.fitnessLevel)

        return RecommendedExercise(
            name: preset.name,
            category: preset.category,
            targetMuscles: preset.targetMuscles,
            suggestedSets: adjustedSets,
            suggestedReps: adjustedReps,
            suggestedWeight: nil,  // 最初はユーザーが決定
            suggestedDuration: preset.defaultDuration,
            restTime: preset.defaultRestTime,
            instructions: preset.instructions,
            matchScore: matchScore
        )
    }

    private func adjustSets(_ baseSets: Int, for level: FitnessLevel) -> Int {
        switch level {
        case .beginner: return max(2, baseSets - 1)
        case .intermediate: return baseSets
        case .advanced: return baseSets + 1
        case .expert: return baseSets + 2
        }
    }

    private func adjustReps(_ baseReps: Int, for level: FitnessLevel) -> Int {
        switch level {
        case .beginner: return max(6, baseReps - 2)
        case .intermediate: return baseReps
        case .advanced: return baseReps + 2
        case .expert: return baseReps + 4
        }
    }

    private func aggregateReasons(from allReasons: [[RecommendationReason]]) -> [RecommendationReason] {
        var aggregated: [RecommendationFactor: (Double, String)] = [:]

        for reasons in allReasons {
            for reason in reasons {
                if let existing = aggregated[reason.factor] {
                    aggregated[reason.factor] = ((existing.0 + reason.score) / 2, reason.explanation)
                } else {
                    aggregated[reason.factor] = (reason.score, reason.explanation)
                }
            }
        }

        return aggregated.map { factor, values in
            RecommendationReason(
                factor: factor,
                score: values.0,
                explanation: values.1
            )
        }.sorted { $0.score > $1.score }
    }

    private func calculateConfidence(scores: [Double], dataPoints: Int) -> Double {
        guard !scores.isEmpty else { return 0.5 }

        // スコアの平均
        let averageScore = scores.reduce(0, +) / Double(scores.count)

        // スコアの一貫性（標準偏差が小さいほど信頼度高）
        let mean = averageScore
        let variance = scores.reduce(0) { $0 + pow($1 - mean, 2) } / Double(scores.count)
        let stdDev = sqrt(variance)
        let consistencyBonus = max(0, 0.2 - stdDev)

        // データ量ボーナス
        let dataBonus = min(0.2, Double(dataPoints) * 0.02)

        return min(0.95, averageScore + consistencyBonus + dataBonus)
    }

    // MARK: - 説明文生成

    private func getGoalAlignmentExplanation(score: Double, goal: FitnessGoalType) -> String {
        if score >= 0.8 {
            return "「\(goal.rawValue)」の目標に非常に適しています"
        } else if score >= 0.5 {
            return "目標達成に貢献しますが、他のエクササイズも組み合わせると効果的です"
        } else {
            return "目標との直接的な関連は低いですが、総合的な健康に有益です"
        }
    }

    private func getFitnessLevelExplanation(score: Double, level: FitnessLevel) -> String {
        if score >= 0.9 {
            return "\(level.rawValue)レベルに最適な難易度です"
        } else if score >= 0.7 {
            return "あなたのレベルで挑戦しがいのある難易度です"
        } else {
            return "段階的に負荷を調整することをお勧めします"
        }
    }

    private func getEquipmentMatchExplanation(score: Double) -> String {
        if score >= 1.0 {
            return "利用可能な器具で実行できます"
        } else if score >= 0.5 {
            return "一部の器具を代替品で対応可能です"
        } else {
            return "追加の器具が必要な場合があります"
        }
    }

    private func getTimeConstraintExplanation(score: Double, targetDuration: Int) -> String {
        if score >= 0.8 {
            return "\(targetDuration)分の目標時間内に収まります"
        } else {
            return "時間に余裕を持って計画してください"
        }
    }

    private func getRecoveryExplanation(score: Double) -> String {
        if score >= 0.9 {
            return "ターゲット筋肉は十分に回復しています"
        } else if score >= 0.6 {
            return "回復はほぼ完了していますが、負荷に注意してください"
        } else {
            return "筋肉がまだ回復中のため、軽めに行うことをお勧めします"
        }
    }

    private func getProgressionExplanation(score: Double) -> String {
        if score >= 0.9 {
            return "過去のパフォーマンスが優秀で、負荷増加の準備ができています"
        } else if score >= 0.7 {
            return "安定したパフォーマンスを維持しています"
        } else {
            return "現在のレベルでの継続練習をお勧めします"
        }
    }
}
