//
//  AddWorkoutView.swift
//  AsaWorkoutLog
//
//  Created on 2025/07/03
//

import SwiftUI

struct AddWorkoutView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var workoutName = ""
    @State private var selectedCategory = WorkoutCategory.other
    @State private var durationMinutes = 30
    @State private var durationSeconds = 0
    @State private var workoutDate = Date()
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    TextField("ワークアウト名", text: $workoutName)
                    
                    Picker("カテゴリ", selection: $selectedCategory) {
                        ForEach(WorkoutCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    
                    DatePicker("日時", selection: $workoutDate)
                }
                
                Section("時間") {
                    HStack {
                        Picker("分", selection: $durationMinutes) {
                            ForEach(0..<181) { minute in
                                Text("\(minute)分")
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(maxWidth: .infinity)
                        
                        Picker("秒", selection: $durationSeconds) {
                            ForEach(0..<60) { second in
                                Text("\(second)秒")
                                    .tag(second)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 120)
                }
                
                Section("メモ") {
                    TextField("メモ（任意）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("ワークアウトを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveWorkout()
                    }
                    .disabled(workoutName.isEmpty)
                }
            }
        }
    }
    
    private func saveWorkout() {
        let totalSeconds = TimeInterval(durationMinutes * 60 + durationSeconds)
        
        let workout = Workout(
            name: workoutName,
            duration: totalSeconds,
            date: workoutDate,
            category: selectedCategory,
            notes: notes
        )
        
        viewModel.addWorkout(workout)
        dismiss()
    }
}

#Preview {
    AddWorkoutView(viewModel: WorkoutViewModel())
}