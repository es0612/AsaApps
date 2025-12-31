//
//  AddTaskView.swift
//  AsaSmartTodo
//
//  タスク追加画面（リアルタイムAI予測付き）
//  タスク入力中に0.5秒デバウンスでAI予測を表示
//

import SwiftUI
import AsaUIKit

struct AddTaskView: View {
    @Bindable var viewModel: SmartTodoViewModel
    @Environment(\.dismiss) private var dismiss

    // フォーム入力
    @State private var title = ""
    @State private var description = ""
    @State private var category: TaskCategory = .other
    @State private var userPriority: PriorityLevel = .medium
    @State private var hasDueDate = false
    @State private var dueDate = Date()

    // AI予測
    @State private var realtimePrediction: PredictionResult?
    @State private var predictionTimer: Timer?
    private let predictor = TaskPriorityPredictor()

    var body: some View {
        NavigationStack {
            Form {
                // タスク基本情報
                Section("タスク情報") {
                    TextField("タイトル", text: $title)
                        .onChange(of: title) {
                            schedulePrediction()
                        }

                    TextField("説明（任意）", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .onChange(of: description) {
                            schedulePrediction()
                        }
                }

                // カテゴリと期限
                Section("詳細") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(TaskCategory.allCases) { cat in
                            HStack {
                                Text(cat.icon)
                                Text(cat.displayName)
                            }
                            .tag(cat)
                        }
                    }
                    .onChange(of: category) {
                        schedulePrediction()
                    }

                    Toggle("期限を設定", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("期限", selection: $dueDate, displayedComponents: .date)
                            .onChange(of: dueDate) {
                                schedulePrediction()
                            }
                    }
                }

                // ユーザー設定優先度
                Section("優先度") {
                    Picker("自分で設定", selection: $userPriority) {
                        ForEach(PriorityLevel.allCases) { priority in
                            HStack {
                                Text(priority.icon)
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // AI予測カード
                if let prediction = realtimePrediction {
                    Section("AI予測") {
                        PredictionCardView(prediction: prediction)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .onTapGesture {
                                // 予測を採用
                                userPriority = prediction.suggestedPriority
                            }
                    }
                }
            }
            .navigationTitle("新しいタスク")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    // MARK: - Methods

    /// タスクを追加
    private func addTask() {
        viewModel.createTask(
            title: title,
            description: description.isEmpty ? nil : description,
            category: category,
            userPriority: userPriority,
            dueDate: hasDueDate ? dueDate : nil
        )

        dismiss()
    }

    /// AI予測をスケジュール（0.5秒デバウンス）
    private func schedulePrediction() {
        // 既存のタイマーをキャンセル
        predictionTimer?.invalidate()

        // タイトルが空の場合は予測しない
        guard !title.isEmpty else {
            realtimePrediction = nil
            return
        }

        // 0.5秒後に予測を実行
        predictionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            performRealtimePrediction()
        }
    }

    /// リアルタイムAI予測を実行
    private func performRealtimePrediction() {
        let prediction = predictor.predictPriorityRealtime(
            title: title,
            description: description.isEmpty ? nil : description,
            category: category,
            dueDate: hasDueDate ? dueDate : nil
        )

        realtimePrediction = prediction
    }
}
