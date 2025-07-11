//
//  PomodoroView.swift
//  AsaPomodoro
//  
//  Created on 2025/07/11
//

import SwiftUI

struct PomodoroView: View {
    @State private var timer = PomodoroTimer()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("AsaSoftCream").opacity(0.8),
                        Color("AsaSoftCream").opacity(0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // ヘッダー情報
                    VStack(spacing: 12) {
                        Text("ポモドーロタイマー")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        
                        HStack {
                            Text("セット \(timer.currentSet)")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(Color("AsaMocha"))
                            
                            Spacer()
                            
                            Text("完了: \(timer.completedSets)")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(Color("AsaMocha"))
                        }
                        .padding(.horizontal)
                    }
                    
                    // 円形プログレスバー
                    CircularProgressView(
                        progress: timer.progress,
                        mode: timer.currentMode,
                        timeText: timer.formattedTime,
                        modeText: timer.modeDisplayText
                    )
                    
                    // コントロールボタン
                    VStack(spacing: 20) {
                        // 開始/一時停止ボタン
                        HStack(spacing: 20) {
                            if timer.isRunning {
                                AsaButton(
                                    title: "一時停止",
                                    action: { timer.pauseTimer() },
                                    color: Color("AsaMutedSage")
                                )
                            } else if timer.isPaused {
                                AsaButton(
                                    title: "再開",
                                    action: { timer.resumeTimer() },
                                    color: Color("AsaCoffeeBrown")
                                )
                            } else {
                                AsaButton(
                                    title: "開始",
                                    action: { timer.startTimer() },
                                    color: Color("AsaCoffeeBrown")
                                )
                            }
                        }
                        
                        // リセットボタン
                        HStack(spacing: 20) {
                            AsaButton(
                                title: "リセット",
                                action: { timer.resetTimer() },
                                color: Color("AsaMocha"),
                                isEnabled: !timer.isRunning
                            )
                            .frame(maxWidth: .infinity)
                            
                            AsaButton(
                                title: "全リセット",
                                action: { timer.resetSession() },
                                color: Color("AsaMutedSage"),
                                isEnabled: !timer.isRunning
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("設定") {
                        showingSettings = true
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
            .sheet(isPresented: $showingSettings) {
                PomodoroSettingsView(timer: timer)
            }
            .onReceive(NotificationCenter.default.publisher(for: .pomodoroSessionCompleted)) { _ in
                // セッション完了時の処理（音声通知など）
                playCompletionSound()
            }
        }
    }
    
    private func playCompletionSound() {
        // 簡単な触覚フィードバック
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
}

struct AsaButton: View {
    let title: String
    let action: () -> Void
    let color: Color
    let isEnabled: Bool
    
    init(title: String, action: @escaping () -> Void, color: Color = Color("AsaCoffeeBrown"), isEnabled: Bool = true) {
        self.title = title
        self.action = action
        self.color = color
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isEnabled ? color : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(radius: 2)
                .scaleEffect(isEnabled ? 1.0 : 0.95)
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

#Preview {
    PomodoroView()
}