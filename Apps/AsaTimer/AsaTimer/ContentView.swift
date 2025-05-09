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
    
    @State private var targetSeconds = 60 // タイマーの目標時間（デフォルト60秒）
    @State private var showAlert = false // アラート表示フラグ
    @State private var inputText = "60" // TextField 入力用
    @State private var history: [TimerRecord] = [] // 履歴データ
    
    
    // MARK: - Computed Properties
    private var formattedTime: String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds) // MM:SS 形式
    }
    
    // MARK: - Methods
    private func startTimer() {
        guard let target = Int(inputText), target > 0 else { return }
        targetSeconds = target
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            seconds += 1
            if seconds >= targetSeconds {
                stopTimer()
                showAlert = true
                // タイマー終了時に履歴を追加
                history.append(TimerRecord(duration: seconds, endTime: Date()))
            }
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
        inputText = "\(targetSeconds)" // 入力欄をリセット
    }
    
    
    // MARK: - Body
    var body: some View {
        TabView {
            ZStack {
                // 背景に薄いクリーム色を重ねて温かみを
                Color("AsaSoftCream").opacity(0.1)
                    .ignoresSafeArea()
                Color("AsaDarkSlate").opacity(0.8)
                    .ignoresSafeArea()
                VStack(spacing: 20) {
                    // タイマー時間入力
                    HStack {
                        Text("タイマー設定（秒）:")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        TextField("秒数を入力", text: $inputText)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .frame(width: 50)
                            .accentColor(Color("AsaCoffeeBrown"))
                            .background(Color("AsaSoftCream").opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // タイマー表示（MM:SS 形式）
                    Text(formattedTime)
                        .font(.system(.largeTitle, design: .rounded))
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .padding()
                        .background(Color("AsaSoftCream").opacity(0.3))
                        .cornerRadius(10)
                        .shadow(radius: 2) // シャドウ追加
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
            .tabItem {
                Label("タイマー", systemImage: "timer")
            }
            
            // 履歴画面
            TimerHistoryView(history: history)
                .tabItem {
                    Label("履歴", systemImage: "clock.arrow.circlepath")
                }
        }
        .accentColor(Color("AsaCoffeeBrown")) // タブバーのアクセントカラー
        .alert("タイマー終了！", isPresented: $showAlert) {
            Button("OK") {
                resetTimer()
            }
            
        } message: {
            Text("設定した時間が経過しました。")
        }
    }
    
}

#Preview {
    ContentView()
}
