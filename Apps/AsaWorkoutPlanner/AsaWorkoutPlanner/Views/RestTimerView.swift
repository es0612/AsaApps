//
//  RestTimerView.swift
//  AsaWorkoutPlanner
//
//  詳細レストタイマー画面
//  カスタマイズ可能な休憩時間管理
//

import SwiftUI
import AsaUIKit
import AVFoundation

struct RestTimerView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @AppStorage("restTimerSound") private var restTimerSound = true

    @State private var timeRemaining: TimeInterval
    @State private var totalTime: TimeInterval
    @State private var isRunning = false
    @State private var timerTask: Task<Void, Never>?
    @State private var selectedPreset: TimeInterval?
    @State private var showingCustomTime = false
    @State private var customMinutes = 1
    @State private var customSeconds = 0

    let onComplete: () -> Void
    let exerciseName: String?
    let autoStart: Bool

    // タイマープリセット
    private let presets: [TimeInterval] = [30, 60, 90, 120, 180]

    // MARK: - Initialization

    init(
        initialTime: TimeInterval = 60,
        exerciseName: String? = nil,
        autoStart: Bool = true,
        onComplete: @escaping () -> Void
    ) {
        self._timeRemaining = State(initialValue: initialTime)
        self._totalTime = State(initialValue: initialTime)
        self._selectedPreset = State(initialValue: initialTime)
        self.exerciseName = exerciseName
        self.autoStart = autoStart
        self.onComplete = onComplete
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(AsaColors.darkSlate),
                    Color(AsaColors.mocha)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                // ヘッダー
                headerView

                Spacer()

                // メインタイマー
                mainTimerView

                Spacer()

                // プリセットボタン
                presetsView

                // コントロールボタン
                controlButtonsView

                Spacer()
            }
            .padding()
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if autoStart {
                // ハプティックフィードバック
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

                // タイマー自動開始
                startTimer()
            }
        }
        .onDisappear {
            timerTask?.cancel()
        }
    }

    // MARK: - Components

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    timerTask?.cancel()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                if let name = exerciseName {
                    Text(name)
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Spacer()

                Button {
                    showingCustomTime = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Text("休憩タイマー")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }

    private var mainTimerView: some View {
        ZStack {
            // 背景円
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 15)
                .frame(width: 280, height: 280)

            // プログレス円
            Circle()
                .trim(from: 0, to: progressValue)
                .stroke(
                    LinearGradient(
                        colors: [Color(AsaColors.coffeeBrown), Color(AsaColors.softCream)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 15, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: timeRemaining)

            // タイマー表示
            VStack(spacing: 8) {
                Text(formatTime(timeRemaining))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    private var presetsView: some View {
        VStack(spacing: 12) {
            Text("プリセット")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            HStack(spacing: 12) {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        setTime(preset)
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(Int(preset))")
                                .font(.headline)
                            Text("秒")
                                .font(.caption2)
                        }
                        .frame(width: 60, height: 50)
                        .background(
                            selectedPreset == preset ?
                            Color(AsaColors.coffeeBrown) :
                            Color.white.opacity(0.2)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isRunning)
                }
            }
        }
    }

    private var controlButtonsView: some View {
        HStack(spacing: 20) {
            // リセットボタン
            Button {
                resetTimer()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .frame(width: 60, height: 60)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            .disabled(timeRemaining == totalTime && !isRunning)

            // 開始/一時停止ボタン
            Button {
                if isRunning {
                    pauseTimer()
                } else {
                    startTimer()
                }
            } label: {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.title)
                    .frame(width: 80, height: 80)
                    .background(Color(AsaColors.coffeeBrown))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }

            // スキップボタン
            Button {
                skipTimer()
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.title2)
                    .frame(width: 60, height: 60)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
        }
        .sheet(isPresented: $showingCustomTime) {
            customTimePickerView
        }
    }

    private var customTimePickerView: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("カスタム時間設定")
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(spacing: 20) {
                    // 分
                    VStack {
                        Text("分")
                            .font(.caption)
                            .foregroundColor(Color(AsaColors.mutedSage))

                        Picker("分", selection: $customMinutes) {
                            ForEach(0..<10) { min in
                                Text("\(min)").tag(min)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100, height: 150)
                    }

                    Text(":")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    // 秒
                    VStack {
                        Text("秒")
                            .font(.caption)
                            .foregroundColor(Color(AsaColors.mutedSage))

                        Picker("秒", selection: $customSeconds) {
                            ForEach(0..<60) { sec in
                                Text("\(sec)").tag(sec)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100, height: 150)
                    }
                }

                Button {
                    let customTime = TimeInterval(customMinutes * 60 + customSeconds)
                    if customTime > 0 {
                        setTime(customTime)
                    }
                    showingCustomTime = false
                } label: {
                    Text("設定")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(AsaColors.coffeeBrown))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        showingCustomTime = false
                    }
                }
            }
        }
        .presentationDetents([.height(400)])
    }

    // MARK: - Computed Properties

    private var progressValue: CGFloat {
        guard totalTime > 0 else { return 0 }
        return CGFloat(timeRemaining / totalTime)
    }

    private var statusText: String {
        if isRunning {
            return "休憩中..."
        } else if timeRemaining == 0 {
            return "休憩完了！"
        } else if timeRemaining == totalTime {
            return "タップして開始"
        } else {
            return "一時停止中"
        }
    }

    // MARK: - Timer Methods

    private func setTime(_ time: TimeInterval) {
        timeRemaining = time
        totalTime = time
        selectedPreset = time
        isRunning = false
        timerTask?.cancel()
    }

    private func startTimer() {
        isRunning = true

        timerTask = Task {
            while timeRemaining > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒

                await MainActor.run {
                    if timeRemaining > 0 {
                        timeRemaining -= 1

                        // 完了時の処理
                        if timeRemaining == 0 {
                            timerCompleted()
                        }
                    }
                }
            }
        }
    }

    private func pauseTimer() {
        isRunning = false
        timerTask?.cancel()
    }

    private func resetTimer() {
        isRunning = false
        timerTask?.cancel()
        timeRemaining = totalTime
    }

    private func skipTimer() {
        isRunning = false
        timerTask?.cancel()
        timeRemaining = 0
        timerCompleted()
    }

    private func timerCompleted() {
        isRunning = false

        // ハプティックフィードバック
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // タイマー音（設定が有効の場合）
        if restTimerSound {
            AudioServicesPlaySystemSound(1005) // システムサウンドID 1005: Tock
        }

        // 完了コールバック実行
        onComplete()

        // 1秒後に自動で閉じる
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                dismiss()
            }
        }
    }

    // MARK: - Helper Methods

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview {
    RestTimerView(
        initialTime: 60,
        exerciseName: "ベンチプレス"
    ) {
        print("タイマー完了")
    }
}
