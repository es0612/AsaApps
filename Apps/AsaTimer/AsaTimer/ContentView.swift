//
//  ContentView.swift
//  AsaTimer
//
//  Created on 2025/05/08
//


import SwiftUI

struct ContentView: View {
    // MARK: - Properties
    @State private var seconds = 0 // タイマーの秒数
    @State private var isRunning = false // タイマー動作中か
    @State private var timer: Timer? // タイマーインスタンス
    
    // MARK: - Methods
    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            seconds += 1
        }
    }
    
    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        stopTimer()
        seconds = 0
    }
    
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // 背景に薄いクリーム色を重ねて温かみを
            Color("AsaSoftCream").opacity(0.1)
                .ignoresSafeArea()
            Color("AsaDarkSlate").opacity(0.9)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                // タイマー表示
                Text("Timer: \(seconds)s")
                    .font(.system(.title, design: .rounded))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                // スタート/ストップボタン
                AsaButton(
                    title: isRunning ? "ストップ" : "スタート",
                    action: {
                        if isRunning {
                            stopTimer()
                        } else {
                            startTimer()
                        }
                    },
                    color: isRunning ? Color("AsaMocha") : Color("AsaCoffeeBrown"),
                    isEnabled: true
                )
                
                // リセットボタン
                AsaButton(
                    title: "リセット",
                    action: resetTimer,
                    color: Color("AsaMutedSage"),
                    isEnabled: seconds > 0 || isRunning
                )
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
