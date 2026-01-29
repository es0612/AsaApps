//
//  AsaVoiceAssistantApp.swift
//  AsaVoiceAssistant
//
//  音声認識でタスク管理を行うボイスアシスタントアプリ
//  日本語の音声コマンドでタスクを作成・完了・削除・一覧確認
//

import SwiftUI
import SwiftData

/// AsaVoiceAssistantアプリのエントリーポイント
///
/// 音声認識を活用したハンズフリータスク管理アプリです。
/// 朝の準備中や運転中など、手が離せない状況でもタスク管理が可能です。
///
/// ## 主な機能
/// - 日本語音声コマンドでタスク操作
/// - リアルタイム音声認識とフィードバック
/// - タスクの作成・完了・削除・一覧表示
/// - 音声読み上げによるタスク確認
///
/// ## 音声コマンド例
/// - 「明日までに報告書を作成」→ タスク作成（期限: 明日）
/// - 「買い物リストを完了」→ タスク完了
/// - 「今日のタスクを教えて」→ タスク読み上げ
@main
struct AsaVoiceAssistantApp: App {
    // MARK: - Properties

    /// データサービス（Swift Data）
    private let dataService: DataService

    // MARK: - Initialization

    init() {
        self.dataService = DataService()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView(dataService: dataService)
        }
        .modelContainer(dataService.modelContainer)
    }
}
