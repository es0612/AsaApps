//
//  TaskFeatureExtractor.swift
//  AsaSmartTodo
//
//  タスクから特徴量を抽出するサービス
//  AI予測エンジンで使用するメトリクスを計算
//

import Foundation

/// タスクから特徴量を抽出するクラス
final class TaskFeatureExtractor {
    /// タイトルの複雑度を計算（0.0-1.0）
    /// 単語数と文字数から判定
    func calculateTitleComplexity(_ title: String) -> Double {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0.0 }

        // 単語数ベースのスコア（最大10単語で1.0）
        let wordCount = trimmed.split(separator: " ").count
        let wordScore = min(Double(wordCount) / 10.0, 1.0)

        // 文字数ベースのスコア（最大50文字で1.0）
        let charCount = trimmed.count
        let charScore = min(Double(charCount) / 50.0, 1.0)

        // 平均を取る
        return (wordScore + charScore) / 2.0
    }

    /// 説明文の複雑度を計算（0.0-1.0）
    /// 文字数と行数から判定
    func calculateDescriptionComplexity(_ description: String?) -> Double {
        guard let description = description, !description.isEmpty else { return 0.0 }

        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0.0 }

        // 文字数ベースのスコア（最大200文字で1.0）
        let charCount = trimmed.count
        let charScore = min(Double(charCount) / 200.0, 1.0)

        // 行数ベースのスコア（最大5行で1.0）
        let lineCount = trimmed.components(separatedBy: .newlines).count
        let lineScore = min(Double(lineCount) / 5.0, 1.0)

        // 平均を取る
        return (charScore + lineScore) / 2.0
    }

    /// 作成時刻から時間帯スコアを計算（0.0-1.0）
    /// 朝活時間帯（5:00-7:00）が最も高いスコア
    func calculateTimeOfDayScore(hour: Int) -> Double {
        switch hour {
        case 5..<7:
            return 0.9  // 朝活時間帯（5:00-7:00）
        case 7..<9:
            return 0.7  // 朝の時間帯
        case 9..<12:
            return 0.6  // 午前中
        case 12..<17:
            return 0.5  // 午後
        case 17..<21:
            return 0.6  // 夕方
        default:
            return 0.3  // 夜間・深夜
        }
    }

    /// 期限までの日数からスコアを計算（0.0-1.0）
    /// 期限が近いほど高いスコア
    func calculateDueDateScore(daysUntilDue: Int?) -> Double {
        guard let days = daysUntilDue else {
            return 0.3  // 期限未設定は低スコア
        }

        switch days {
        case ...0:
            return 1.0  // 期限切れ（緊急）
        case 1:
            return 0.9  // 明日が期限
        case 2...3:
            return 0.7  // 2-3日後
        case 4...7:
            return 0.5  // 1週間以内
        case 8...14:
            return 0.4  // 2週間以内
        default:
            return 0.3  // それ以上先
        }
    }

    /// 期限までの日数を計算
    func calculateDaysUntilDue(from dueDate: Date?) -> Int? {
        guard let dueDate = dueDate else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: dueDate)
        return components.day
    }

    /// タスクのすべての特徴量を抽出
    func extractFeatures(from task: SmartTask) -> TaskFeatures {
        let titleComplexity = calculateTitleComplexity(task.title)
        let descriptionComplexity = calculateDescriptionComplexity(task.taskDescription)
        let daysUntilDue = calculateDaysUntilDue(from: task.dueDate)
        let timeOfDayScore = calculateTimeOfDayScore(hour: task.createdHour)
        let dueDateScore = calculateDueDateScore(daysUntilDue: daysUntilDue)
        let categoryImportance = task.category.importanceWeight

        return TaskFeatures(
            titleComplexity: titleComplexity,
            descriptionComplexity: descriptionComplexity,
            daysUntilDue: daysUntilDue,
            createdHour: task.createdHour,
            categoryImportanceScore: categoryImportance,
            timeOfDayScore: timeOfDayScore,
            dueDateScore: dueDateScore
        )
    }
}

/// タスクの特徴量を保持する構造体
struct TaskFeatures: Codable, Sendable {
    /// タイトルの複雑度（0.0-1.0）
    let titleComplexity: Double

    /// 説明文の複雑度（0.0-1.0）
    let descriptionComplexity: Double

    /// 期限までの日数（nilは期限未設定）
    let daysUntilDue: Int?

    /// 作成時刻（0-23時）
    let createdHour: Int

    /// カテゴリの重要度スコア（0.0-1.0）
    let categoryImportanceScore: Double

    /// 時間帯スコア（0.0-1.0）
    let timeOfDayScore: Double

    /// 期限スコア（0.0-1.0）
    let dueDateScore: Double
}
