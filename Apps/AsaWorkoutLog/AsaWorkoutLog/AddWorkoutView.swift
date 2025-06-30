//
//  AddWorkoutView.swift
//  AsaWorkoutLog
//  
//  Created on 2025/07/01
//

import SwiftUI

struct AddWorkoutView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedWorkoutType: WorkoutType = .walking
    @State private var selectedIntensity: WorkoutIntensity = .moderate
    @State private var selectedDate = Date()
    @State private var duration: TimeInterval = 1800 // 30分
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("運動の詳細")) {
                    // 運動種類選択
                    Picker("運動の種類", selection: $selectedWorkoutType) {
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            HStack {
                                Text(type.emoji)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    // 強度選択
                    Picker("強度", selection: $selectedIntensity) {
                        ForEach(WorkoutIntensity.allCases, id: \.self) { intensity in
                            HStack {
                                Text(intensity.emoji)
                                Text(intensity.displayName)
                            }
                            .tag(intensity)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("時間と日付")) {
                    // 日付選択
                    DatePicker("日付", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                    
                    // 時間選択
                    VStack(alignment: .leading, spacing: 8) {
                        Text("運動時間: \(formatDuration(duration))")
                            .font(.subheadline)
                        
                        Slider(value: $duration, in: 300...7200, step: 300) // 5分から2時間まで、5分刻み
                            .accentColor(Color("AsaCoffeeBrown"))
                    }
                }
                
                Section(header: Text("メモ（任意）")) {
                    TextField("運動についてのメモ", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    VStack(spacing: 8) {
                        Text("予想消費カロリー")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(estimatedCalories)kcal")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("運動を記録")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveWorkout()
                }
                .fontWeight(.semibold)
                .foregroundColor(Color("AsaCoffeeBrown"))
            )
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
    
    private var estimatedCalories: Int {
        let minutes = duration / 60
        let baseCalories = selectedWorkoutType.estimatedCaloriesPerMinute * minutes
        let adjustedCalories = baseCalories * selectedIntensity.multiplier
        return Int(adjustedCalories)
    }
    
    private func saveWorkout() {
        let newSession = WorkoutSession(
            date: selectedDate,
            workoutType: selectedWorkoutType,
            duration: duration,
            intensity: selectedIntensity,
            caloriesBurned: estimatedCalories,
            notes: notes.isEmpty ? nil : notes
        )
        
        viewModel.addWorkoutSession(newSession)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    AddWorkoutView(viewModel: WorkoutViewModel())
}