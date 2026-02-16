//
//  MorningRoutineAttributes.swift
//  PapaHubWidgetExtension
//
//  朝活ルーティン Live Activity の属性定義
//  ActivityKit を使用したリアルタイム進捗表示
//

import ActivityKit
import Foundation

// MARK: - MorningRoutineAttributes

/// 朝活ルーティンの Live Activity 属性
struct MorningRoutineAttributes: ActivityAttributes {
    /// ルーティン実行日
    var routineDate: Date

    /// 目標時間（分）
    var targetDurationMinutes: Int

    // MARK: - ContentState

    /// Live Activity の動的コンテンツ
    public struct ContentState: Codable, Hashable {
        /// 現在のアイテム名
        var currentItemName: String

        /// 現在のアイテムアイコン
        var currentItemIcon: String

        /// 完了済みアイテム数
        var completedCount: Int

        /// 全アイテム数
        var totalCount: Int

        /// 経過時間（分）
        var elapsedMinutes: Int

        /// 現在のスコア
        var currentScore: Int
    }
}
