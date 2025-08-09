//
//  VoiceMemoViewModel.swift
//  AsaVoiceMemo
//  
//  Created on 2025/07/28
//

import Foundation
import SwiftData
import AVFoundation

@Observable
class VoiceMemoViewModel {
    // Managers
    let audioRecorderManager = AudioRecorderManager()
    let audioPlayerManager = AudioPlayerManager()
    
    // State
    var isShowingRecordingView = false
    var isShowingMicrophonePermissionAlert = false
    var alertMessage = ""
    var selectedVoiceMemo: VoiceMemo?
    
    // Model Context（SwiftDataのコンテキスト）
    private var modelContext: ModelContext?
    
    init() {
        // 初期化処理
    }
    
    // ModelContextの設定
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - 録音関連
    
    // 録音開始の準備
    func prepareToRecord() async {
        let hasPermission = await audioRecorderManager.requestMicrophonePermission()
        
        if hasPermission {
            isShowingRecordingView = true
        } else {
            alertMessage = "音声録音にはマイクへのアクセス許可が必要です。設定アプリでマイクへのアクセスを許可してください。"
            isShowingMicrophonePermissionAlert = true
        }
    }
    
    // 録音開始
    func startRecording() {
        let success = audioRecorderManager.startRecording()
        if !success {
            alertMessage = audioRecorderManager.recordingError ?? "録音の開始に失敗しました"
            isShowingMicrophonePermissionAlert = true
        }
    }
    
    // 安全な録音開始（許可確認付き）
    func startRecordingSafely() async {
        let hasPermission = await audioRecorderManager.requestMicrophonePermission()
        
        if hasPermission {
            let success = audioRecorderManager.startRecording()
            if !success {
                alertMessage = audioRecorderManager.recordingError ?? "録音の開始に失敗しました"
                isShowingMicrophonePermissionAlert = true
            }
        } else {
            alertMessage = "音声録音にはマイクへのアクセス許可が必要です。設定アプリでマイクへのアクセスを許可してください。"
            isShowingMicrophonePermissionAlert = true
        }
    }
    
    // 録音停止して保存
    func stopRecordingAndSave() {
        audioRecorderManager.stopRecording()
        
        guard let recordingURL = audioRecorderManager.currentRecordingURL else {
            alertMessage = "録音ファイルが見つかりませんでした"
            isShowingMicrophonePermissionAlert = true
            return
        }
        
        // タイトルを生成（録音日時ベース）
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        let title = "録音 \(formatter.string(from: Date()))"
        
        // VoiceMemoを作成して保存
        let voiceMemo = VoiceMemo(
            title: title,
            fileURL: recordingURL,
            duration: audioRecorderManager.recordingDuration
        )
        
        saveVoiceMemo(voiceMemo)
        isShowingRecordingView = false
    }
    
    // 録音キャンセル
    func cancelRecording() {
        audioRecorderManager.cancelRecording()
        isShowingRecordingView = false
    }
    
    // MARK: - 再生関連
    
    // 音声メモを再生
    func playVoiceMemo(_ voiceMemo: VoiceMemo) {
        // 既に同じメモが再生中の場合は一時停止/再開
        if audioPlayerManager.currentVoiceMemo?.id == voiceMemo.id {
            audioPlayerManager.togglePlayPause()
        } else {
            // 別のメモを再生
            audioPlayerManager.loadVoiceMemo(voiceMemo)
            audioPlayerManager.play()
        }
    }
    
    // 再生停止
    func stopPlaying() {
        audioPlayerManager.stop()
    }
    
    // MARK: - データ管理
    
    // VoiceMemoを保存
    private func saveVoiceMemo(_ voiceMemo: VoiceMemo) {
        guard let context = modelContext else {
            alertMessage = "データの保存に失敗しました"
            isShowingMicrophonePermissionAlert = true
            return
        }
        
        context.insert(voiceMemo)
        
        do {
            try context.save()
        } catch {
            alertMessage = "データの保存に失敗しました: \(error.localizedDescription)"
            isShowingMicrophonePermissionAlert = true
        }
    }
    
    // VoiceMemoを削除
    func deleteVoiceMemo(_ voiceMemo: VoiceMemo) {
        guard let context = modelContext else { return }
        
        // 再生中の場合は停止
        if audioPlayerManager.currentVoiceMemo?.id == voiceMemo.id {
            audioPlayerManager.stop()
        }
        
        // ファイルを削除
        try? FileManager.default.removeItem(at: voiceMemo.fileURL)
        
        // データベースから削除
        context.delete(voiceMemo)
        
        do {
            try context.save()
        } catch {
            alertMessage = "データの削除に失敗しました: \(error.localizedDescription)"
            isShowingMicrophonePermissionAlert = true
        }
    }
    
    // VoiceMemoのタイトルを更新
    func updateVoiceMemoTitle(_ voiceMemo: VoiceMemo, newTitle: String) {
        guard let context = modelContext else { return }
        
        voiceMemo.title = newTitle
        voiceMemo.updatedAt = Date()
        
        do {
            try context.save()
        } catch {
            alertMessage = "データの更新に失敗しました: \(error.localizedDescription)"
            isShowingMicrophonePermissionAlert = true
        }
    }
    
    // MARK: - ユーティリティ
    
    // 現在再生中のVoiceMemoかチェック
    func isCurrentlyPlaying(_ voiceMemo: VoiceMemo) -> Bool {
        return audioPlayerManager.currentVoiceMemo?.id == voiceMemo.id && audioPlayerManager.isPlaying
    }
    
    // 総録音時間を計算
    func getTotalRecordingTime(for voiceMemos: [VoiceMemo]) -> String {
        let totalDuration = voiceMemos.reduce(0) { $0 + $1.duration }
        let hours = Int(totalDuration) / 3600
        let minutes = Int(totalDuration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
    
    // 録音数の統計
    func getRecordingCount(for voiceMemos: [VoiceMemo]) -> String {
        return "\(voiceMemos.count)件の録音"
    }
}