//
//  CircularProgressView.swift
//  AsaPomodoro
//  
//  Created on 2025/07/11
//

import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let mode: PomodoroMode
    let timeText: String
    let modeText: String
    
    private var progressColor: Color {
        switch mode {
        case .work:
            return Color("AsaCoffeeBrown")
        case .shortBreak:
            return Color("AsaMutedSage")
        case .longBreak:
            return Color("AsaMocha")
        }
    }
    
    private var backgroundColor: Color {
        switch mode {
        case .work:
            return Color("AsaCoffeeBrown").opacity(0.2)
        case .shortBreak:
            return Color("AsaMutedSage").opacity(0.2)
        case .longBreak:
            return Color("AsaMocha").opacity(0.2)
        }
    }
    
    var body: some View {
        ZStack {
            // 背景円
            Circle()
                .stroke(backgroundColor, lineWidth: 20)
                .frame(width: 250, height: 250)
            
            // プログレス円
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .frame(width: 250, height: 250)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            // 中央のテキスト
            VStack(spacing: 8) {
                Text(timeText)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(progressColor)
                
                Text(modeText)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(progressColor.opacity(0.8))
            }
        }
    }
}

#Preview {
    VStack(spacing: 50) {
        CircularProgressView(
            progress: 0.7,
            mode: .work,
            timeText: "15:30",
            modeText: "作業時間"
        )
        
        CircularProgressView(
            progress: 0.3,
            mode: .shortBreak,
            timeText: "03:45",
            modeText: "短い休憩"
        )
        
        CircularProgressView(
            progress: 0.8,
            mode: .longBreak,
            timeText: "12:00",
            modeText: "長い休憩"
        )
    }
    .background(Color("AsaSoftCream"))
}