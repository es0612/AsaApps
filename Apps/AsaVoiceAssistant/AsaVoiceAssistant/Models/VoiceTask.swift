//
//  VoiceTask.swift
//  AsaVoiceAssistant
//
//  音声アシスタントで管理するタスクモデル
//

import Foundation
import SwiftData

/// 音声アシスタントで管理するタスク
///
/// Swift Dataの`@Model`マクロを使用した永続化対応モデルです。
/// 音声で作成されたタスクには元の音声認識テキストも保存されます。
@Model
final class VoiceTask {
    // MARK: - Properties

    /// 一意識別子
    @Attribute(.unique) var id: UUID

    /// タスクのタイトル
    var title: String

    /// タスクの詳細説明（オプション）
    var taskDescription: String?

    /// 優先度（Raw Value形式で保存）
    var priorityRawValue: String

    /// カテゴリ（Raw Value形式で保存）
    var categoryRawValue: String

    /// 期限日時（オプション）
    var dueDate: Date?

    /// 完了状態
    var isCompleted: Bool

    /// 完了日時
    var completedAt: Date?

    /// 元の音声認識テキスト（音声で作成された場合）
    var originalTranscription: String?

    /// 音声で作成されたかどうか
    var createdByVoice: Bool

    /// 作成日時
    var createdAt: Date

    /// 更新日時
    var updatedAt: Date

    // MARK: - Computed Properties

    /// 優先度（enum）
    var priority: PriorityLevel {
        get { PriorityLevel(rawValue: priorityRawValue) ?? .medium }
        set { priorityRawValue = newValue.rawValue }
    }

    /// カテゴリ（enum）
    var category: TaskCategory {
        get { TaskCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    /// 期限切れかどうか
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }

    /// 今日期限かどうか
    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    /// 明日期限かどうか
    var isDueTomorrow: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInTomorrow(dueDate)
    }

    /// 今週中期限かどうか
    var isDueThisWeek: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDate(dueDate, equalTo: Date(), toGranularity: .weekOfYear)
    }

    /// 期限の表示文字列
    var dueDateDisplayText: String? {
        guard let dueDate = dueDate else { return nil }

        if isDueToday {
            return "今日"
        } else if isDueTomorrow {
            return "明日"
        } else if isOverdue {
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.unitsStyle = .full
            return "期限切れ（\(formatter.localizedString(for: dueDate, relativeTo: Date()))）"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: dueDate)
        }
    }

    // MARK: - Initializer

    init(
        title: String,
        description: String? = nil,
        priority: PriorityLevel = .medium,
        category: TaskCategory = .other,
        dueDate: Date? = nil,
        originalTranscription: String? = nil,
        createdByVoice: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = description
        self.priorityRawValue = priority.rawValue
        self.categoryRawValue = category.rawValue
        self.dueDate = dueDate
        self.isCompleted = false
        self.completedAt = nil
        self.originalTranscription = originalTranscription
        self.createdByVoice = createdByVoice
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods

    /// タスクを完了としてマーク
    func complete() {
        isCompleted = true
        completedAt = Date()
        updatedAt = Date()
    }

    /// タスクを未完了に戻す
    func uncomplete() {
        isCompleted = false
        completedAt = nil
        updatedAt = Date()
    }

    /// タスクの詳細を更新
    func update(
        title: String? = nil,
        description: String? = nil,
        priority: PriorityLevel? = nil,
        category: TaskCategory? = nil,
        dueDate: Date? = nil
    ) {
        if let title = title {
            self.title = title
        }
        if let description = description {
            self.taskDescription = description
        }
        if let priority = priority {
            self.priorityRawValue = priority.rawValue
        }
        if let category = category {
            self.categoryRawValue = category.rawValue
        }
        if let dueDate = dueDate {
            self.dueDate = dueDate
        }
        self.updatedAt = Date()
    }

    /// 読み上げ用のテキストを生成
    func toSpeechText() -> String {
        var text = title

        if let dueDateText = dueDateDisplayText {
            text += "、期限は\(dueDateText)"
        }

        if priority == .high {
            text += "、優先度高"
        }

        return text
    }
}
