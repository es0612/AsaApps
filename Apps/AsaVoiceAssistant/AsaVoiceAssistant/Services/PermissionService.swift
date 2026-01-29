//
//  PermissionService.swift
//  AsaVoiceAssistant
//
//  マイクと音声認識の権限管理サービス
//

import Foundation
import AVFoundation
import Speech
import UIKit

/// 権限の状態を表すenum
enum PermissionStatus: Sendable {
    case notDetermined  // 未確認
    case authorized     // 許可済み
    case denied         // 拒否
    case restricted     // 制限（ペアレンタルコントロール等）
}

/// マイクと音声認識の権限管理サービス
///
/// 音声認識機能を使用するために必要な権限（マイク、音声認識）の
/// 状態確認とリクエストを管理します。
@MainActor
@Observable
final class PermissionService {
    // MARK: - Properties

    /// マイク権限の状態
    private(set) var microphoneStatus: PermissionStatus = .notDetermined

    /// 音声認識権限の状態
    private(set) var speechRecognitionStatus: PermissionStatus = .notDetermined

    /// すべての権限が許可されているか
    var isFullyAuthorized: Bool {
        microphoneStatus == .authorized && speechRecognitionStatus == .authorized
    }

    /// 権限チェック中か
    private(set) var isChecking = false

    /// エラーメッセージ
    private(set) var errorMessage: String?

    // MARK: - Initialization

    init() {
        checkCurrentPermissions()
    }

    // MARK: - Permission Check

    /// 現在の権限状態を確認
    func checkCurrentPermissions() {
        checkMicrophonePermission()
        checkSpeechRecognitionPermission()
    }

    /// マイク権限の状態を確認
    private func checkMicrophonePermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .undetermined:
            microphoneStatus = .notDetermined
        case .granted:
            microphoneStatus = .authorized
        case .denied:
            microphoneStatus = .denied
        @unknown default:
            microphoneStatus = .notDetermined
        }
    }

    /// 音声認識権限の状態を確認
    private func checkSpeechRecognitionPermission() {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .notDetermined:
            speechRecognitionStatus = .notDetermined
        case .authorized:
            speechRecognitionStatus = .authorized
        case .denied:
            speechRecognitionStatus = .denied
        case .restricted:
            speechRecognitionStatus = .restricted
        @unknown default:
            speechRecognitionStatus = .notDetermined
        }
    }

    // MARK: - Permission Request

    /// すべての必要な権限をリクエスト
    func requestAllPermissions() async {
        isChecking = true
        errorMessage = nil

        // マイク権限をリクエスト
        await requestMicrophonePermission()

        // 音声認識権限をリクエスト
        await requestSpeechRecognitionPermission()

        isChecking = false
    }

    /// マイク権限をリクエスト
    func requestMicrophonePermission() async {
        guard microphoneStatus == .notDetermined else { return }

        let granted = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        microphoneStatus = granted ? .authorized : .denied

        if !granted {
            errorMessage = "マイクの使用が許可されていません。設定から許可してください。"
        }
    }

    /// 音声認識権限をリクエスト
    func requestSpeechRecognitionPermission() async {
        guard speechRecognitionStatus == .notDetermined else { return }

        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        switch status {
        case .authorized:
            speechRecognitionStatus = .authorized
        case .denied:
            speechRecognitionStatus = .denied
            errorMessage = "音声認識が許可されていません。設定から許可してください。"
        case .restricted:
            speechRecognitionStatus = .restricted
            errorMessage = "音声認識が制限されています。"
        case .notDetermined:
            speechRecognitionStatus = .notDetermined
        @unknown default:
            speechRecognitionStatus = .notDetermined
        }
    }

    // MARK: - Helper Methods

    /// 権限状態の詳細メッセージを取得
    func getStatusMessage() -> String {
        if isFullyAuthorized {
            return "すべての権限が許可されています"
        }

        var messages: [String] = []

        switch microphoneStatus {
        case .notDetermined:
            messages.append("マイク: 未確認")
        case .denied:
            messages.append("マイク: 拒否")
        case .restricted:
            messages.append("マイク: 制限")
        case .authorized:
            break
        }

        switch speechRecognitionStatus {
        case .notDetermined:
            messages.append("音声認識: 未確認")
        case .denied:
            messages.append("音声認識: 拒否")
        case .restricted:
            messages.append("音声認識: 制限")
        case .authorized:
            break
        }

        return messages.isEmpty ? "権限が必要です" : messages.joined(separator: "\n")
    }

    /// 設定アプリを開く
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            Task { @MainActor in
                await UIApplication.shared.open(url)
            }
        }
    }
}
