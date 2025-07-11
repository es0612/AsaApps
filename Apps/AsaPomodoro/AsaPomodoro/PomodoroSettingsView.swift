//
//  PomodoroSettingsView.swift
//  AsaPomodoro
//  
//  Created on 2025/07/11
//

import SwiftUI

struct PomodoroSettingsView: View {
    @Bindable var timer: PomodoroTimer
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("タイマー設定") {
                    HStack {
                        Text("作業時間")
                        Spacer()
                        Text("\(Int(timer.workDuration / 60))分")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("短い休憩")
                        Spacer()
                        Text("\(Int(timer.shortBreakDuration / 60))分")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("長い休憩")
                        Spacer()
                        Text("\(Int(timer.longBreakDuration / 60))分")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("長い休憩までのセット数")
                        Spacer()
                        Text("\(timer.setsBeforeLongBreak)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
        }
    }
}

#Preview {
    PomodoroSettingsView(timer: PomodoroTimer())
}