//
//  VoiceCommand.swift
//  AsaVoiceAssistant
//
//  音声コマンド解析結果モデル
//

import Foundation

/// 音声コマンドの解析結果を表す構造体
///
/// `CommandParserService`が音声認識テキストを解析した結果を格納します。
/// 解析されたインテント、タスク情報、フィルタ条件などを含みます。
struct VoiceCommand: Sendable, Equatable {
    // MARK: - Properties

    /// 検出されたコマンドの意図
    let intent: CommandIntent

    /// タスクのタイトル（createTask時に使用）
    let taskTitle: String?

    /// 推定された優先度（createTask時に使用）
    let priority: PriorityLevel?

    /// 推定されたカテゴリ（createTask時に使用）
    let category: TaskCategory?

    /// 期限日時（createTask時に使用）
    let dueDate: Date?

    /// 操作対象タスクの検索クエリ（completeTask, deleteTask時に使用）
    let targetTaskQuery: String?

    /// フィルタ用優先度（listTasks, readTasks時に使用）
    let filterPriority: PriorityLevel?

    /// フィルタ用カテゴリ（listTasks, readTasks時に使用）
    let filterCategory: TaskCategory?

    /// 元の音声認識テキスト
    let rawTranscription: String

    /// 解析の信頼度スコア（0.0〜1.0）
    let confidence: Double

    /// 解析日時
    let parsedAt: Date

    // MARK: - Initializer

    init(
        intent: CommandIntent,
        taskTitle: String? = nil,
        priority: PriorityLevel? = nil,
        category: TaskCategory? = nil,
        dueDate: Date? = nil,
        targetTaskQuery: String? = nil,
        filterPriority: PriorityLevel? = nil,
        filterCategory: TaskCategory? = nil,
        rawTranscription: String,
        confidence: Double
    ) {
        self.intent = intent
        self.taskTitle = taskTitle
        self.priority = priority
        self.category = category
        self.dueDate = dueDate
        self.targetTaskQuery = targetTaskQuery
        self.filterPriority = filterPriority
        self.filterCategory = filterCategory
        self.rawTranscription = rawTranscription
        self.confidence = confidence
        self.parsedAt = Date()
    }

    // MARK: - Computed Properties

    /// コマンドが有効かどうか
    var isValid: Bool {
        switch intent {
        case .createTask:
            return taskTitle != nil && !taskTitle!.isEmpty
        case .completeTask, .deleteTask:
            return targetTaskQuery != nil && !targetTaskQuery!.isEmpty
        case .listTasks, .readTasks:
            return true
        case .unknown:
            return false
        }
    }

    /// コマンドの概要説明（確認画面用）
    var summary: String {
        switch intent {
        case .createTask:
            var parts = ["「\(taskTitle ?? "")」を作成"]
            if let dueDate = dueDate {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "ja_JP")
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                parts.append("期限: \(formatter.string(from: dueDate))")
            }
            if let priority = priority {
                parts.append("優先度: \(priority.displayName)")
            }
            if let category = category {
                parts.append("カテゴリ: \(category.displayName)")
            }
            return parts.joined(separator: " / ")
        case .completeTask:
            return "「\(targetTaskQuery ?? "")」を完了"
        case .deleteTask:
            return "「\(targetTaskQuery ?? "")」を削除"
        case .listTasks:
            var parts = ["タスク一覧を表示"]
            if let filterPriority = filterPriority {
                parts.append("\(filterPriority.displayName)優先度のみ")
            }
            if let filterCategory = filterCategory {
                parts.append("\(filterCategory.displayName)カテゴリのみ")
            }
            return parts.joined(separator: " / ")
        case .readTasks:
            return "タスクを読み上げ"
        case .unknown:
            return "不明なコマンド"
        }
    }

    // MARK: - Factory Methods

    /// 不明なコマンドを生成
    static func unknown(rawTranscription: String) -> VoiceCommand {
        VoiceCommand(
            intent: .unknown,
            rawTranscription: rawTranscription,
            confidence: 0.0
        )
    }
}
