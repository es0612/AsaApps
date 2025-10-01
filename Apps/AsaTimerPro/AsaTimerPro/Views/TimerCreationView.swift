//
//  TimerCreationView.swift
//  AsaTimerPro
//
//  Created on 2025/09/05
//

import SwiftUI

struct TimerCreationView: View {
    @Bindable var viewModel: MultiTimerViewModel
    @Environment(\.colorScheme) var colorScheme
    
    // フォーム状態
    @State private var timerName: String = ""
    @State private var selectedCategory: TimerCategory = .general
    @State private var duration: Int = 1500 // デフォルト25分
    @State private var memo: String = ""
    @State private var isRepeating: Bool = false
    @State private var customDurationMinutes: String = "25"
    @State private var usePresetDuration: Bool = true
    
    // UI状態
    @State private var showingPreview: Bool = false
    @State private var showingSuccessAlert: Bool = false
    @State private var validationError: String = ""
    @State private var showingValidationError: Bool = false
    
    // プリセット時間（秒）
    private let presetDurations: [(name: String, seconds: Int)] = [
        ("5分", 300),
        ("10分", 600),
        ("15分", 900),
        ("25分", 1500),
        ("30分", 1800),
        ("45分", 2700),
        ("1時間", 3600),
        ("2時間", 7200)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color(colorScheme == .dark ? "AsaDarkSlate" : "AsaSoftCream")
                    .opacity(0.1)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // タイマー名入力
                        timerNameSection
                        
                        // カテゴリ選択
                        categorySelectionSection
                        
                        // 時間設定
                        durationSelectionSection
                        
                        // メモ入力
                        memoSection
                        
                        // 詳細設定
                        advancedSettingsSection
                        
                        // プレビューセクション
                        if !timerName.isEmpty {
                            previewSection
                        }
                        
                        // 作成ボタン
                        createButtonSection
                    }
                    .padding()
                }
            }
            .navigationTitle("新規タイマー")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("リセット") {
                        resetForm()
                    }
                    .foregroundColor(Color("AsaMutedSage"))
                }
            }
        }
        .alert("タイマーを作成しました", isPresented: $showingSuccessAlert) {
            Button("OK") {
                resetForm()
            }
        } message: {
            Text("「\(timerName)」のタイマーを作成しました。")
        }
        .alert("入力エラー", isPresented: $showingValidationError) {
            Button("OK") {}
        } message: {
            Text(validationError)
        }
    }
    
    // MARK: - Sections
    
    private var timerNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("タイマー名")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
            
            TextField("タイマーの名前を入力", text: $timerName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
        }
    }
    
    private var categorySelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリ")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(TimerCategory.allCases) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.title2)
                                .foregroundColor(selectedCategory == category ? .white : category.color)
                            
                            Text(category.displayName)
                                .font(.caption)
                                .foregroundColor(selectedCategory == category ? .white : category.color)
                        }
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedCategory == category ? category.color : category.color.opacity(0.1)
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(category.color, lineWidth: selectedCategory == category ? 2 : 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var durationSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("時間設定")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
            
            // プリセット・カスタム切り替え
            Picker("時間設定方法", selection: $usePresetDuration) {
                Text("プリセット").tag(true)
                Text("カスタム").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if usePresetDuration {
                // プリセット時間選択
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(presetDurations, id: \.seconds) { preset in
                        Button(action: {
                            duration = preset.seconds
                        }) {
                            Text(preset.name)
                                .font(.caption)
                                .foregroundColor(duration == preset.seconds ? .white : Color("AsaCoffeeBrown"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    duration == preset.seconds ? Color("AsaCoffeeBrown") : Color("AsaCoffeeBrown").opacity(0.1)
                                )
                                .cornerRadius(8)
                        }
                    }
                }
            } else {
                // カスタム時間入力
                HStack {
                    TextField("分数", text: $customDurationMinutes)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(width: 80)
                        .onChange(of: customDurationMinutes) { newValue in
                            if let minutes = Int(newValue), minutes > 0 {
                                duration = minutes * 60
                            }
                        }
                    
                    Text("分")
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("(\(formatDuration(duration)))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("メモ（任意）")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
            
            TextField("メモを入力", text: $memo, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...5)
        }
    }
    
    private var advancedSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("詳細設定")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Toggle(isOn: $isRepeating) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("繰り返しタイマー")
                        .foregroundColor(Color("AsaDarkSlate"))
                    Text("完了後に自動的にリセットして再開します")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .tint(Color("AsaCoffeeBrown"))
        }
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("プレビュー")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
            
            TimerCardView(
                session: createPreviewSession(),
                onStart: {},
                onPause: {},
                onStop: {},
                onDelete: {}
            )
            .disabled(true)
            .opacity(0.8)
        }
    }
    
    private var createButtonSection: some View {
        VStack(spacing: 12) {
            AsaButton(
                title: "タイマーを作成",
                action: createTimer,
                color: Color("AsaCoffeeBrown"),
                isEnabled: isFormValid
            )
            
            if !viewModel.canStartNewTimer {
                Text("最大同時実行数に達しています。既存のタイマーを停止してから作成してください。")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        return !timerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               duration > 0
    }
    
    // MARK: - Methods
    
    private func createTimer() {
        guard isFormValid else {
            validationError = "タイマー名を入力し、正しい時間を設定してください。"
            showingValidationError = true
            return
        }
        
        let trimmedName = timerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        
        viewModel.addTimer(
            name: trimmedName,
            category: selectedCategory,
            duration: duration,
            memo: trimmedMemo.isEmpty ? nil : trimmedMemo,
            isRepeating: isRepeating
        )
        
        showingSuccessAlert = true
    }
    
    private func resetForm() {
        timerName = ""
        selectedCategory = .general
        duration = 1500
        memo = ""
        isRepeating = false
        customDurationMinutes = "25"
        usePresetDuration = true
    }
    
    private func createPreviewSession() -> TimerSession {
        return TimerSession(
            name: timerName.isEmpty ? "プレビュータイマー" : timerName,
            category: selectedCategory,
            duration: duration,
            memo: memo.isEmpty ? nil : memo,
            isRepeating: isRepeating
        )
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
}

#Preview {
    TimerCreationView(viewModel: MultiTimerViewModel())
}