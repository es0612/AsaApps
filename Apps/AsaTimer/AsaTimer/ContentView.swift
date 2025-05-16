//
//  ContentView.swift
//  AsaTimer
//
//  Created on 2025/05/08
//


import SwiftUI
import AVFoundation

struct ContentView: View {
    // MARK: - Properties
    @State private var seconds = 0 // タイマーの秒数
    @State private var isRunning = false // タイマー動作中か
    @State private var timer: Timer? // タイマーインスタンス
    
    @State private var targetSeconds = 60 // タイマーの目標時間（デフォルト60秒）
    @State private var showAlert = false // アラート表示フラグ
    @State private var inputText = "60" // TextField 入力用
    @State private var history: [TimerRecord] = []  {
        didSet {
            saveHistory() // 履歴が更新されるたびに保存
        }
    }// 履歴データ
    @State private var repeatTimer = false // 繰り返しタイマー設定
    @State private var currentRepeatCount = 1 // 現在の繰り返し回数
    
    @State private var playSound = true // サウンド再生のオン/オフ
    private var audioPlayer: AVAudioPlayer?
    
    let presetTimes = [60, 300, 600] // 1分、5分、10分
    @State private var selectedPresetTime = 60 // 選択されたプリセット時間
    
    // プログレスバーの進行状況
    private var progress: Double {
        targetSeconds > 0 ? Double(seconds) / Double(targetSeconds) : 0.0
    }
    
    @State private var pulseAnimation = false // パルスアニメーションの状態
    
    // MARK: - Init
    init() {
        // サウンドファイルの準備
        if let soundURL = Bundle.main.url(forResource: "notification", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Error loading sound file: \(error)")
            }
        }
    }
    
    // MARK: - Computed Properties
    private var formattedTime: String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds) // MM:SS 形式
    }
    
    // MARK: - Methods
    private func playNotificationSound() {
        if playSound {
            audioPlayer?.play()
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "timerHistory"),
           let savedHistory = try? JSONDecoder().decode([TimerRecord].self, from: data) {
            history = savedHistory
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "timerHistory")
        }
    }
    
    private func startTimer() {
        guard let target = Int(inputText), target > 0 else { return }
        targetSeconds = target
        isRunning = true
        
        // パルスアニメーションをトリガー
        withAnimation(.easeInOut(duration: 0.5).repeatCount(2, autoreverses: true)) {
            pulseAnimation = true
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            seconds += 1
            if seconds >= targetSeconds {
                history.append(TimerRecord(duration: targetSeconds, endTime: Date(), repeatCount: currentRepeatCount))
                if repeatTimer {
                    seconds = 0
                    currentRepeatCount += 1 // 繰り返し回数をインクリメント
                    playNotificationSound()
                    // 繰り返しタイマーでもパルスを再トリガー
                    withAnimation(.easeInOut(duration: 0.5).repeatCount(2, autoreverses: true)) {
                        pulseAnimation = true
                    }
                } else {
                    stopTimer()
                    showAlert = true
                    playNotificationSound()
                }
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
        currentRepeatCount = 1 // 繰り返し回数をリセット
        pulseAnimation = false // パルスアニメーションをリセット
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
                
                VStack(spacing: 15) {
                    // プリセットタイマー選択
                    Picker("プリセット時間", selection: $selectedPresetTime) {
                        ForEach(presetTimes, id: \.self) { time in
                            Text("\(time / 60)分").tag(time)
                        }
                    }
                    .pickerStyle(.menu)
                    .accentColor(Color("AsaCoffeeBrown"))
                    .padding(.horizontal)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("AsaSoftCream").opacity(0.2))
                            .padding(.horizontal, -8)
                    )
                    .onChange(of: selectedPresetTime) { newValue in
                        inputText = "\(newValue)"
                        targetSeconds = newValue
                    }
                    
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
                            .onChange(of: inputText) { newValue in
                                if let newTarget = Int(newValue) {
                                    targetSeconds = newTarget
                                    selectedPresetTime = presetTimes.contains(newTarget) ? newTarget : presetTimes[0]
                                }
                            }
                    }
                    .padding(.horizontal)
                    
                    // スライダーによる時間調整
                    VStack {
                        Text("タイマー時間: \(Int(targetSeconds / 60))分")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        Slider(value: Binding<Double>(
                            get: { Double(targetSeconds) },
                            set: { newValue in
                                targetSeconds = Int(newValue)
                                inputText = "\(targetSeconds)"
                                selectedPresetTime = presetTimes.contains(targetSeconds) ? targetSeconds : presetTimes[0]
                            }
                        ), in: 60...3600, step: 60)
                        .accentColor(Color("AsaMocha"))
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                    
                    // 繰り返しタイマーのトグル
                    Toggle(isOn: $repeatTimer) {
                        Text("タイマーを繰り返す")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    .padding(.horizontal)
                    .tint(Color("AsaMocha")) // トグルの色をブランドカラーに
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("AsaSoftCream").opacity(0.2))
                            .padding(.horizontal, -8)
                    )
                    // サウンド再生のトグル
                    Toggle(isOn: $playSound) {
                        Text("サウンド通知")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    .padding(.horizontal)
                    .tint(Color("AsaMocha"))
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("AsaSoftCream").opacity(0.2))
                            .padding(.horizontal, -8)
                    )
                                        
                    // タイマー表示とプログレスバー
                    ZStack {
                        Circle()
                            .stroke(Color("AsaSoftCream").opacity(0.3), lineWidth: 10)
                            .frame(width: 120, height: 120)
                        CircularProgress(progress: progress)
                            .stroke(Color("AsaMocha"), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .animation(.linear(duration: 1.0), value: progress)
                        Text(formattedTime)
                            .font(.system(.largeTitle, design: .rounded))
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0) // パルスアニメーション
                    .padding()
                    
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
            TimerHistoryView(history: $history)
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
        .onAppear {
            loadHistory() // アプリ起動時に履歴を読み込み
        }
    }
}

#Preview {
    ContentView()
}
