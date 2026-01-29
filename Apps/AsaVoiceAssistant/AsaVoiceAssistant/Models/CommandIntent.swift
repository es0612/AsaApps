//
//  CommandIntent.swift
//  AsaVoiceAssistant
//
//  音声コマンドの意図（インテント）定義
//

import Foundation

/// 音声コマンドの意図を表すenum
///
/// ユーザーが発話したコマンドの目的を分類します。
/// コマンドパーサーが音声認識結果を解析し、適切なインテントを特定します。
enum CommandIntent: String, CaseIterable, Sendable {
    /// タスクを新規作成
    case createTask

    /// タスクを完了としてマーク
    case completeTask

    /// タスクを削除
    case deleteTask

    /// タスク一覧を表示
    case listTasks

    /// タスクを音声で読み上げ
    case readTasks

    /// 不明なコマンド
    case unknown

    /// コマンドの日本語表示名
    var displayName: String {
        switch self {
        case .createTask:
            return "タスク作成"
        case .completeTask:
            return "タスク完了"
        case .deleteTask:
            return "タスク削除"
        case .listTasks:
            return "タスク一覧"
        case .readTasks:
            return "タスク読み上げ"
        case .unknown:
            return "不明"
        }
    }

    /// コマンド検出用のキーワードパターン
    ///
    /// 正規表現パターンの配列を返します。
    /// これらのパターンにマッチした場合、該当するインテントと判定されます。
    var patterns: [String] {
        switch self {
        case .createTask:
            return [
                "(.+)(を|って)(追加|作成|登録|入れて|作って)",
                "(.+)(まで|までに)(.+)(を|って|する)",
                "(.+)(する|やる|しなきゃ|しないと)",
                "新しいタスク(.+)",
                "タスク(.+)を(追加|作成)"
            ]
        case .completeTask:
            return [
                "(.+)(を|って)(完了|終わり|終了|済み|done|Done)",
                "(.+)(終わった|できた|完成)",
                "(.+)(を|って)(チェック|消す)"
            ]
        case .deleteTask:
            return [
                "(.+)(を|って)(削除|消して|取り消し|キャンセル)",
                "(.+)(いらない|不要)"
            ]
        case .listTasks:
            return [
                "(今日|明日|今週)の(タスク|予定|やること)(を|って|は|)(見せて|教えて|表示|一覧)",
                "(タスク|予定|やること)(を|の|)(一覧|リスト|全部|確認)",
                "何(が|を)(ある|やる|やらなきゃ)",
                "(高|中|低)優先度(の|)(タスク|やること)(を|って|)(見せて|教えて|表示)"
            ]
        case .readTasks:
            return [
                "(今日|明日|今週)の(タスク|予定|やること)(を|って)(読んで|読み上げて|言って)",
                "(タスク|予定)(を|って)(読んで|読み上げて)",
                "何(が|を)(ある|やる)か(読んで|教えて)"
            ]
        case .unknown:
            return []
        }
    }

    /// インテントのアイコン（SF Symbol）
    var iconName: String {
        switch self {
        case .createTask:
            return "plus.circle.fill"
        case .completeTask:
            return "checkmark.circle.fill"
        case .deleteTask:
            return "trash.fill"
        case .listTasks:
            return "list.bullet"
        case .readTasks:
            return "speaker.wave.2.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }
}
