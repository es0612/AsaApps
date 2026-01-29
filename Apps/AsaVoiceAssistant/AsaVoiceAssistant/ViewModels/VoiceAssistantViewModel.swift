//
//  VoiceAssistantViewModel.swift
//  AsaVoiceAssistant
//
//  メインViewModel - 音声アシスタント機能の統括
//

import Foundation
import SwiftUI

/// 音声アシスタントの処理状態
enum AssistantState: Equatable {
    case idle                       // 待機中
    case listening                  // 音声入力中
    case processing                 // コマンド解析中
    case confirming(VoiceCommand)   // コマンド確認中
    case executing                  // コマンド実行中
    case success(String)            // 成功
    case error(String)              // エラー
}

/// 音声アシスタントのメインViewModel
///
/// 音声認識、コマンド解析、タスク操作、音声フィードバックを統括します。
/// 音声入力→コマンド解析→確認→実行→フィードバックの一連のフローを管理します。
@MainActor
@Observable
final class VoiceAssistantViewModel {
    // MARK: - Dependencies

    private let dataService: DataService
    let speechRecognitionService: SpeechRecognitionService
    let textToSpeechService: TextToSpeechService
    let permissionService: PermissionService
    private let commandParser: CommandParserService

    // MARK: - State

    /// アシスタントの処理状態
    private(set) var state: AssistantState = .idle

    /// 現在のタスクリスト
    private(set) var tasks: [VoiceTask] = []

    /// 解析されたコマンド（確認画面用）
    private(set) var parsedCommand: VoiceCommand?

    /// 読み込み中フラグ
    private(set) var isLoading = false

    /// エラーメッセージ
    private(set) var errorMessage: String?

    // MARK: - Settings

    /// 設定
    private(set) var settings: VoiceSettings

    /// コマンド確認をスキップするか
    var skipConfirmation: Bool {
        !settings.showCommandConfirmation
    }

    // MARK: - Computed Properties

    /// 認識中のテキスト
    var recognizedText: String {
        speechRecognitionService.recognizedText
    }

    /// 音声レベル（波形表示用）
    var audioLevel: Float {
        speechRecognitionService.audioLevel
    }

    /// 音声入力中かどうか
    var isListening: Bool {
        if case .listening = state { return true }
        return false
    }

    /// 未完了タスク
    var activeTasks: [VoiceTask] {
        tasks.filter { !$0.isCompleted }
    }

    /// 完了済みタスク
    var completedTasks: [VoiceTask] {
        tasks.filter { $0.isCompleted }
    }

    /// 今日期限のタスク
    var todayTasks: [VoiceTask] {
        tasks.filter { $0.isDueToday && !$0.isCompleted }
    }

    /// 期限切れタスク
    var overdueTasks: [VoiceTask] {
        tasks.filter { $0.isOverdue }
    }

    // MARK: - Initialization

    init(dataService: DataService) {
        self.dataService = dataService
        self.speechRecognitionService = SpeechRecognitionService()
        self.textToSpeechService = TextToSpeechService()
        self.permissionService = PermissionService()
        self.commandParser = CommandParserService.shared
        self.settings = dataService.getSettings()

        // 設定を各サービスに適用
        applySettings()
    }

    // MARK: - Public Methods

    /// アプリ起動時の初期化
    func initialize() async {
        isLoading = true

        // 権限をチェック・リクエスト
        await permissionService.requestAllPermissions()

        // タスクを読み込み
        loadTasks()

        isLoading = false
    }

    /// タスクを読み込み
    func loadTasks() {
        tasks = dataService.fetchAllTasks()
    }

    // MARK: - Voice Recognition

    /// 音声入力を開始
    func startListening() async {
        guard permissionService.isFullyAuthorized else {
            state = .error("マイクと音声認識の権限が必要です")
            return
        }

        do {
            state = .listening
            errorMessage = nil
            try await speechRecognitionService.startRecognition()
        } catch {
            state = .error("音声認識の開始に失敗しました")
            errorMessage = error.localizedDescription
        }
    }

    /// 音声入力を停止して処理
    func stopListeningAndProcess() {
        speechRecognitionService.stopRecognition()
        processRecognizedText()
    }

    /// 音声入力をキャンセル
    func cancelListening() {
        speechRecognitionService.cancelRecognition()
        state = .idle
        parsedCommand = nil
    }

    /// 認識テキストを処理
    private func processRecognizedText() {
        let text = speechRecognitionService.finalText

        guard !text.isEmpty else {
            state = .idle
            return
        }

        state = .processing

        // コマンドを解析
        let command = commandParser.parse(text)
        parsedCommand = command

        if command.intent == .unknown {
            state = .error("コマンドを認識できませんでした")
            if settings.enableVoiceFeedback {
                textToSpeechService.speak("コマンドを認識できませんでした。もう一度お試しください。")
            }
            return
        }

        // 確認をスキップする場合は直接実行
        if skipConfirmation {
            executeCommand(command)
        } else {
            state = .confirming(command)
        }
    }

    // MARK: - Command Execution

    /// コマンドを実行（確認画面から呼び出し）
    func confirmAndExecute() {
        guard let command = parsedCommand else { return }
        executeCommand(command)
    }

    /// コマンドを拒否（確認画面から呼び出し）
    func cancelCommand() {
        state = .idle
        parsedCommand = nil
    }

    /// コマンドを実行
    func executeCommand(_ command: VoiceCommand) {
        state = .executing

        switch command.intent {
        case .createTask:
            createTask(from: command)

        case .completeTask:
            completeTask(from: command)

        case .deleteTask:
            deleteTask(from: command)

        case .listTasks:
            listTasks(from: command)

        case .readTasks:
            readTasks(from: command)

        case .unknown:
            state = .error("不明なコマンドです")
        }
    }

    // MARK: - Task Operations

    /// タスクを作成
    private func createTask(from command: VoiceCommand) {
        guard let title = command.taskTitle, !title.isEmpty else {
            state = .error("タスクタイトルを取得できませんでした")
            return
        }

        let task = VoiceTask(
            title: title,
            priority: command.priority ?? settings.defaultPriority,
            category: command.category ?? settings.defaultCategory,
            dueDate: command.dueDate,
            originalTranscription: command.rawTranscription,
            createdByVoice: true
        )

        dataService.saveTask(task)
        loadTasks()

        state = .success("タスクを作成しました")

        if settings.enableVoiceFeedback {
            textToSpeechService.speakCommandResult(command, success: true)
        }

        // 2秒後にアイドル状態に戻る
        resetStateAfterDelay()
    }

    /// タスクを完了
    private func completeTask(from command: VoiceCommand) {
        guard let query = command.targetTaskQuery else {
            state = .error("タスクを特定できませんでした")
            return
        }

        // タスクを検索
        let matchingTasks = dataService.searchTasks(query: query)
            .filter { !$0.isCompleted }

        if let task = matchingTasks.first {
            task.complete()
            dataService.save()
            loadTasks()

            state = .success("「\(task.title)」を完了しました")

            if settings.enableVoiceFeedback {
                textToSpeechService.speakCommandResult(command, success: true)
            }
        } else {
            state = .error("「\(query)」に一致するタスクが見つかりませんでした")

            if settings.enableVoiceFeedback {
                textToSpeechService.speak("タスクが見つかりませんでした")
            }
        }

        resetStateAfterDelay()
    }

    /// タスクを削除
    private func deleteTask(from command: VoiceCommand) {
        guard let query = command.targetTaskQuery else {
            state = .error("タスクを特定できませんでした")
            return
        }

        // タスクを検索
        let matchingTasks = dataService.searchTasks(query: query)

        if let task = matchingTasks.first {
            let title = task.title
            dataService.deleteTask(task)
            loadTasks()

            state = .success("「\(title)」を削除しました")

            if settings.enableVoiceFeedback {
                textToSpeechService.speakCommandResult(command, success: true)
            }
        } else {
            state = .error("「\(query)」に一致するタスクが見つかりませんでした")

            if settings.enableVoiceFeedback {
                textToSpeechService.speak("タスクが見つかりませんでした")
            }
        }

        resetStateAfterDelay()
    }

    /// タスク一覧を表示
    private func listTasks(from command: VoiceCommand) {
        // フィルタを適用
        var filteredTasks = activeTasks

        if let priority = command.filterPriority {
            filteredTasks = filteredTasks.filter { $0.priority == priority }
        }

        if let category = command.filterCategory {
            filteredTasks = filteredTasks.filter { $0.category == category }
        }

        // タスクは自動的にUIに表示される
        state = .success("\(filteredTasks.count)件のタスクがあります")
        resetStateAfterDelay()
    }

    /// タスクを読み上げ
    private func readTasks(from command: VoiceCommand) {
        var filteredTasks = activeTasks

        if let priority = command.filterPriority {
            filteredTasks = filteredTasks.filter { $0.priority == priority }
        }

        if let category = command.filterCategory {
            filteredTasks = filteredTasks.filter { $0.category == category }
        }

        textToSpeechService.speakTasks(filteredTasks)
        state = .success("タスクを読み上げています")
        resetStateAfterDelay(delay: 5.0)
    }

    // MARK: - Manual Task Operations

    /// 手動でタスクを追加
    func addTask(title: String, description: String? = nil, priority: PriorityLevel, category: TaskCategory, dueDate: Date?) {
        let task = VoiceTask(
            title: title,
            description: description,
            priority: priority,
            category: category,
            dueDate: dueDate,
            createdByVoice: false
        )

        dataService.saveTask(task)
        loadTasks()
    }

    /// タスクの完了状態を切り替え
    func toggleTaskCompletion(_ task: VoiceTask) {
        if task.isCompleted {
            task.uncomplete()
        } else {
            task.complete()
        }
        dataService.save()
        loadTasks()
    }

    /// タスクを削除
    func deleteTask(_ task: VoiceTask) {
        dataService.deleteTask(task)
        loadTasks()
    }

    /// 完了済みタスクを全削除
    func deleteAllCompletedTasks() {
        dataService.deleteCompletedTasks()
        loadTasks()
    }

    // MARK: - Settings

    /// 設定を更新
    func updateSettings() {
        settings.update()
        dataService.updateSettings(settings)
        applySettings()
    }

    /// 設定をリセット
    func resetSettings() {
        settings.resetToDefaults()
        dataService.updateSettings(settings)
        applySettings()
    }

    /// 設定を各サービスに適用
    private func applySettings() {
        speechRecognitionService.configure(
            silenceTimeout: settings.silenceTimeout,
            maxDuration: settings.maxRecordingDuration
        )

        textToSpeechService.configure(
            rate: Float(settings.speechRate),
            pitch: Float(settings.speechPitch),
            volume: Float(settings.speechVolume)
        )
    }

    // MARK: - Utility

    /// 一定時間後に状態をアイドルに戻す
    private func resetStateAfterDelay(delay: Double = 2.0) {
        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            if case .success = state {
                state = .idle
            } else if case .error = state {
                state = .idle
            }
            parsedCommand = nil
        }
    }
}
