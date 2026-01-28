//
//  GameWebSocketProtocol.swift
//  AsaMultiplayerGame
//
//  ゲーム用WebSocket通信サービスのプロトコル定義
//

import Foundation

/// WebSocket接続の状態
enum ConnectionState: Equatable, Sendable {
    /// 切断状態
    case disconnected

    /// 接続中
    case connecting

    /// 接続完了
    case connected

    /// 再接続中
    case reconnecting(attempt: Int)

    /// 接続失敗
    case failed(String)

    /// 表示用テキスト
    var displayText: String {
        switch self {
        case .disconnected:
            return "未接続"
        case .connecting:
            return "接続中..."
        case .connected:
            return "接続済み"
        case .reconnecting(let attempt):
            return "再接続中 (\(attempt)回目)"
        case .failed(let message):
            return "接続失敗: \(message)"
        }
    }

    /// 接続中かどうか
    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }

    /// アイコン名
    var iconName: String {
        switch self {
        case .disconnected:
            return "wifi.slash"
        case .connecting, .reconnecting:
            return "wifi.exclamationmark"
        case .connected:
            return "wifi"
        case .failed:
            return "wifi.slash"
        }
    }
}

/// ゲーム用WebSocket通信サービスのプロトコル
///
/// テスト容易性のためにプロトコルで定義し、
/// 実装とモックを切り替え可能にします。
protocol GameWebSocketServiceProtocol: AnyObject, Sendable {
    /// 現在の接続状態
    var connectionState: ConnectionState { get }

    /// 接続されているルームコード
    var currentRoomCode: String? { get }

    /// メッセージ受信時のコールバック
    var onMessageReceived: (@Sendable (GameMessage) -> Void)? { get set }

    /// 接続状態変更時のコールバック
    var onConnectionStateChanged: (@Sendable (ConnectionState) -> Void)? { get set }

    /// WebSocketサーバーに接続
    /// - Parameters:
    ///   - url: サーバーURL
    ///   - roomCode: 参加するルームコード
    ///   - player: 参加するプレイヤー情報
    func connect(to url: URL, roomCode: String, player: Player) async throws

    /// 接続を切断
    func disconnect()

    /// メッセージを送信
    /// - Parameter message: 送信するメッセージ
    func send(_ message: GameMessage) async throws
}
