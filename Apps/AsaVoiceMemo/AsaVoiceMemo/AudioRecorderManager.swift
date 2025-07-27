//
//  AudioRecorderManager.swift
//  AsaVoiceMemo
//  
//  Created on 2025/07/28
//

import Foundation
import AVFoundation
import Combine

@Observable
class AudioRecorderManager: NSObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    
    var isRecording = false
    var recordingDuration: TimeInterval = 0
    var currentRecordingURL: URL?
    var recordingError: String?
    
    // 録音時間の更新用
    var formattedRecordingTime: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    deinit {
        stopRecording()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            recordingError = "オーディオセッションの設定に失敗しました: \(error.localizedDescription)"
        }
    }
    
    // マイクの権限をリクエスト
    func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    // 録音開始
    func startRecording() -> Bool {
        guard !isRecording else { return false }
        
        // 録音ファイルのURLを生成
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        let audioURL = documentsPath.appendingPathComponent(fileName)
        
        // 録音設定
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            
            if audioRecorder?.record() == true {
                isRecording = true
                currentRecordingURL = audioURL
                recordingDuration = 0
                recordingError = nil
                startRecordingTimer()
                return true
            } else {
                recordingError = "録音の開始に失敗しました"
                return false
            }
        } catch {
            recordingError = "録音の設定に失敗しました: \(error.localizedDescription)"
            return false
        }
    }
    
    // 録音停止
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        isRecording = false
        stopRecordingTimer()
    }
    
    // 録音中断（ファイルを削除）
    func cancelRecording() {
        guard isRecording else { return }
        
        stopRecording()
        
        // 録音ファイルを削除
        if let url = currentRecordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        currentRecordingURL = nil
        recordingDuration = 0
    }
    
    // 録音時間を更新するタイマー
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }
            self.recordingDuration = recorder.currentTime
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    // 録音レベルを取得（オプション機能）
    func getRecordingLevel() -> Float {
        guard let recorder = audioRecorder, recorder.isRecording else { return 0.0 }
        recorder.updateMeters()
        return recorder.averagePower(forChannel: 0)
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorderManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
        stopRecordingTimer()
        
        if !flag {
            recordingError = "録音が正常に完了しませんでした"
            // 失敗した場合はファイルを削除
            if let url = currentRecordingURL {
                try? FileManager.default.removeItem(at: url)
                currentRecordingURL = nil
            }
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        recordingError = "録音エラー: \(error?.localizedDescription ?? "不明なエラー")"
        isRecording = false
        stopRecordingTimer()
    }
}