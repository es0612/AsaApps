import Foundation
import CoreML
import AsaUIKit

@MainActor
class TaskPriorityPredictor {
    // MARK: - Properties

    private var model: MLModel?
    private var featureExtractor: TaskFeatureExtractor

    // 優先度スコアの重み付け（初期はルールベース）
    private let weights = PriorityWeights(
        dueDateWeight: 0.35,
        titleComplexityWeight: 0.15,
        descriptionWeight: 0.10,
        categoryWeight: 0.20,
        timeOfDayWeight: 0.10,
        historicalWeight: 0.10
    )

    // MARK: - Initialization

    init() async {
        self.featureExtractor = TaskFeatureExtractor()
        await loadModel()
    }

    // MARK: - Model Loading

    private func loadModel() async {
        // 将来的にCore MLモデルをロード
        // 現時点ではルールベース予測を使用
        print("TaskPriorityPredictor initialized with rule-based prediction")
    }

    // MARK: - Prediction

    func predictPriority(for task: SmartTask) async -> PredictionResult {
        let features = featureExtractor.extractFeatures(from: task)

        // Core MLモデルが利用可能な場合はモデル予測を使用
        if let prediction = await predictWithModel(features: features) {
            return prediction
        }

        // そうでない場合はルールベース予測を使用
        return predictWithRules(task: task, features: features)
    }

    // MARK: - Model-based Prediction

    private func predictWithModel(features: TaskFeatures) async -> PredictionResult? {
        guard let model = model else { return nil }

        // TODO: Core MLモデル実装時に以下を実装
        // 1. featuresをMLFeatureProviderに変換
        // 2. model.prediction()を呼び出し
        // 3. 結果をPredictionResultに変換

        return nil
    }

    // MARK: - Rule-based Prediction

    private func predictWithRules(task: SmartTask, features: TaskFeatures) -> PredictionResult {
        var priorityScore: Double = 0.0
        var reasoningComponents: [String] = []

        // 1. 期限による優先度計算
        if let daysUntilDue = features.daysUntilDue {
            let dueDateScore: Double
            switch daysUntilDue {
            case ...0:
                dueDateScore = 1.0
                reasoningComponents.append("🚨 期限切れ")
            case 1:
                dueDateScore = 0.9
                reasoningComponents.append("⚠️ 明日が期限")
            case 2...3:
                dueDateScore = 0.7
                reasoningComponents.append("📅 期限が近い（\(daysUntilDue)日後）")
            case 4...7:
                dueDateScore = 0.5
                reasoningComponents.append("📆 今週中の期限")
            default:
                dueDateScore = 0.3
            }
            priorityScore += dueDateScore * weights.dueDateWeight
        }

        // 2. タイトルの複雑度
        let titleScore = min(Double(features.titleWordCount) / 10.0, 1.0)
        priorityScore += titleScore * weights.titleComplexityWeight
        if features.titleWordCount > 5 {
            reasoningComponents.append("📝 詳細なタスク内容")
        }

        // 3. 説明文の詳細度
        let descriptionScore = min(features.descriptionComplexity, 1.0)
        priorityScore += descriptionScore * weights.descriptionWeight
        if features.descriptionComplexity > 0.5 {
            reasoningComponents.append("📋 詳細な説明あり")
        }

        // 4. カテゴリの重要度
        let categoryScore = features.categoryImportanceScore
        priorityScore += categoryScore * weights.categoryWeight
        switch task.category {
        case .work:
            reasoningComponents.append("💼 仕事関連")
        case .family:
            reasoningComponents.append("👨‍👩‍👧‍👦 家族優先")
        case .health:
            reasoningComponents.append("🏥 健康関連")
        case .learning:
            reasoningComponents.append("📚 学習・成長")
        default:
            break
        }

        // 5. 作成時刻（朝活ボーナス）
        let timeScore = calculateTimeOfDayScore(hour: features.createdHour)
        priorityScore += timeScore * weights.timeOfDayWeight
        if features.createdHour >= 5 && features.createdHour < 7 {
            reasoningComponents.append("🌅 朝活時間に作成")
        }

        // 6. 過去の完了率（利用可能な場合）
        if let historicalRate = features.historicalCompletionRate {
            priorityScore += historicalRate * weights.historicalWeight
            if historicalRate < 0.5 {
                reasoningComponents.append("📊 類似タスクの完了率が低い")
            }
        }

        // 優先度の決定
        let suggestedPriority: TaskPriority
        let confidenceScore: Double

        if priorityScore >= 0.7 {
            suggestedPriority = .high
            confidenceScore = min(priorityScore, 0.95)
        } else if priorityScore >= 0.4 {
            suggestedPriority = .medium
            confidenceScore = 0.7 + (priorityScore - 0.4) * 0.5
        } else {
            suggestedPriority = .low
            confidenceScore = 0.5 + priorityScore * 0.5
        }

        // 理由の生成
        let reasoning: String
        if reasoningComponents.isEmpty {
            reasoning = "標準的なタスクと判断しました"
        } else {
            reasoning = reasoningComponents.joined(separator: " / ")
        }

        return PredictionResult(
            suggestedPriority: suggestedPriority,
            confidenceScore: confidenceScore,
            reasoning: reasoning,
            features: features
        )
    }

    // MARK: - Helper Methods

    private func calculateTimeOfDayScore(hour: Int) -> Double {
        switch hour {
        case 5..<7:  // 早朝（朝活）
            return 0.9
        case 7..<9:  // 朝
            return 0.7
        case 9..<12: // 午前
            return 0.6
        case 12..<17: // 午後
            return 0.5
        case 17..<21: // 夕方
            return 0.6
        default:     // 夜
            return 0.3
        }
    }

    // MARK: - Model Training Support

    func collectTrainingData(from tasks: [SmartTask]) -> [(features: TaskFeatures, label: TaskPriority)] {
        return tasks.compactMap { task in
            guard task.feedbackProvided else { return nil }
            let features = featureExtractor.extractFeatures(from: task)
            return (features, task.userPriority)
        }
    }

    func updateModelWeights(basedOn feedback: [(task: SmartTask, accepted: Bool)]) {
        // 将来的な実装: フィードバックに基づいて重み付けを調整
        // 現在は固定の重み付けを使用
    }
}

// MARK: - Supporting Types

struct PriorityWeights {
    let dueDateWeight: Double
    let titleComplexityWeight: Double
    let descriptionWeight: Double
    let categoryWeight: Double
    let timeOfDayWeight: Double
    let historicalWeight: Double
}

// MARK: - Feature Extractor

class TaskFeatureExtractor {
    func extractFeatures(from task: SmartTask) -> TaskFeatures {
        // タイトルの単語数
        let titleWordCount = task.title.split(separator: " ").count

        // 説明文の複雑度（文字数ベース）
        let descriptionComplexity = Double(task.taskDescription?.count ?? 0) / 100.0

        // 期限までの日数
        var daysUntilDue: Int?
        if let dueDate = task.dueDate {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
            daysUntilDue = days
        }

        // 作成時刻
        let createdHour = Calendar.current.component(.hour, from: task.createdAt)

        // カテゴリの重要度スコア
        let categoryImportanceScore = calculateCategoryImportance(task.category)

        // 過去の完了率（簡易版 - 実際はデータベースから取得）
        let historicalCompletionRate: Double? = nil

        return TaskFeatures(
            titleWordCount: titleWordCount,
            descriptionComplexity: descriptionComplexity,
            daysUntilDue: daysUntilDue,
            createdHour: createdHour,
            categoryImportanceScore: categoryImportanceScore,
            historicalCompletionRate: historicalCompletionRate
        )
    }

    private func calculateCategoryImportance(_ category: TaskCategory) -> Double {
        switch category {
        case .work:
            return 0.8
        case .health:
            return 0.7
        case .family:
            return 0.7
        case .learning:
            return 0.6
        case .personal:
            return 0.5
        case .other:
            return 0.4
        }
    }

    func extractKeywords(from text: String) -> [String] {
        // 重要キーワードの抽出（簡易版）
        let importantWords = ["緊急", "重要", "締切", "必須", "優先", "至急", "今日", "明日", "会議", "提出"]
        let words = text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        return words.filter { importantWords.contains($0) }
    }
}