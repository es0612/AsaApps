import SwiftUI
import Observation // @Observable を使うために必要

@Observable
class Stopwatch {
    var elapsedTime: TimeInterval = 0
    var isRunning: Bool = false
    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0 // 停止時の経過時間を保持

    func start() {
        isRunning = true
        startTime = Date()
        startTime = Date().addingTimeInterval(-pausedTime) // 停止時の時間を考慮
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            self.elapsedTime = Date().timeIntervalSince(startTime)
        }
    }

    func stop() {
        isRunning = false
        pausedTime = elapsedTime // 停止時の経過時間を保存
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        isRunning = false
        elapsedTime = 0
        pausedTime = 0 // リセット時に保持時間もクリア
        timer?.invalidate()
        timer = nil
        startTime = nil
    }

    func formattedTime() -> String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let milliseconds = Int(elapsedTime * 100) % 100
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}
