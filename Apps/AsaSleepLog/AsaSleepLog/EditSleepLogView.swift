//
//  EditSleepLogView.swift
//  AsaSleepLog
//  
//  Created on 2025/06/26
//

import SwiftUI

struct EditSleepLogView: View {
    @ObservedObject var viewModel: SleepLogViewModel
    @Environment(\.dismiss) private var dismiss
    
    let originalLog: SleepLog
    @State private var bedTime: Date
    @State private var wakeTime: Date
    @State private var fellAsleepTime: Date
    @State private var selectedQuality: SleepQuality
    @State private var selectedMood: MoodRating?
    @State private var wakeUpCount: Int
    @State private var notes: String
    @State private var showAdvancedOptions: Bool
    @State private var showConflictAlert = false
    
    init(viewModel: SleepLogViewModel, log: SleepLog) {
        self.viewModel = viewModel
        self.originalLog = log
        self._bedTime = State(initialValue: log.bedTime)
        self._wakeTime = State(initialValue: log.wakeTime)
        self._fellAsleepTime = State(initialValue: log.fellAsleepTime ?? log.bedTime)
        self._selectedQuality = State(initialValue: log.quality)
        self._selectedMood = State(initialValue: log.mood)
        self._wakeUpCount = State(initialValue: log.wakeUpCount)
        self._notes = State(initialValue: log.notes ?? "")
        self._showAdvancedOptions = State(initialValue: log.fellAsleepTime != nil || log.wakeUpCount > 0)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ScrollView {
                    VStack(spacing: 20) {
                        TimeSettingSection(
                            bedTime: $bedTime,
                            wakeTime: $wakeTime
                        )
                        .padding(.horizontal)
                        
                        SleepQualitySection(selectedQuality: $selectedQuality)
                            .padding(.horizontal)
                        
                        MoodRatingSection(selectedMood: $selectedMood)
                            .padding(.horizontal)
                        
                        // 詳細オプション
                        EditAdvancedOptionsSection(
                            showAdvancedOptions: $showAdvancedOptions,
                            fellAsleepTime: $fellAsleepTime,
                            wakeUpCount: $wakeUpCount
                        )
                        .padding(.horizontal)
                        
                        NotesSection(notes: $notes)
                            .padding(.horizontal)
                    }
                }
                
                AsaButton(title: "変更を保存") {
                    saveChanges()
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("睡眠記録を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
            .alert("時間の重複", isPresented: $showConflictAlert) {
                Button("OK") { }
            } message: {
                Text("選択された時間は他の記録と重複しています。別の時間を選択してください。")
            }
        }
    }
    
    private func saveChanges() {
        // 時間重複チェック（自分自身を除外）
        if viewModel.hasTimeConflict(bedTime: bedTime, wakeTime: wakeTime, excludingId: originalLog.id) {
            showConflictAlert = true
            return
        }
        
        let updatedLog = SleepLog(
            id: originalLog.id,
            date: originalLog.date,
            bedTime: bedTime,
            wakeTime: wakeTime,
            quality: selectedQuality,
            notes: notes.isEmpty ? nil : notes,
            fellAsleepTime: showAdvancedOptions ? fellAsleepTime : nil,
            wakeUpCount: showAdvancedOptions ? wakeUpCount : 0,
            mood: selectedMood
        )
        
        viewModel.updateSleepLog(updatedLog)
        dismiss()
    }
}

struct EditAdvancedOptionsSection: View {
    @Binding var showAdvancedOptions: Bool
    @Binding var fellAsleepTime: Date
    @Binding var wakeUpCount: Int
    
    var body: some View {
        AsaCard {
            VStack(spacing: 15) {
                Button(action: {
                    withAnimation {
                        showAdvancedOptions.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        Text("詳細オプション")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        Spacer()
                        Image(systemName: showAdvancedOptions ? "chevron.up" : "chevron.down")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
                
                if showAdvancedOptions {
                    VStack(spacing: 15) {
                        // 入眠時間
                        HStack {
                            Image(systemName: "zzz")
                                .foregroundColor(Color("AsaMutedSage"))
                                .font(.caption)
                            Text("入眠時間")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            DatePicker("", selection: $fellAsleepTime, displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                                .scaleEffect(0.9)
                        }
                        
                        // 夜中に起きた回数
                        HStack {
                            Image(systemName: "eye")
                                .foregroundColor(Color("AsaMutedSage"))
                                .font(.caption)
                            Text("夜中に起きた回数")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Stepper("\(wakeUpCount)回", value: $wakeUpCount, in: 0...10)
                                .frame(width: 120)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    EditSleepLogView(
        viewModel: SleepLogViewModel(),
        log: SleepLog(
            date: Date(),
            bedTime: Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date()) ?? Date(),
            wakeTime: Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date()) ?? Date(),
            quality: .good,
            notes: "テストメモ"
        )
    )
}