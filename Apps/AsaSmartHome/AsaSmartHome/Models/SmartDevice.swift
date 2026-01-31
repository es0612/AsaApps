import Foundation
import SwiftData

// MARK: - SmartDevice Model

/// スマートホームデバイスの基本モデル
/// Swift Dataで永続化され、デバイス固有の情報はmetadataに格納
@Model
final class SmartDevice {
    // MARK: - Properties

    @Attribute(.unique) var id: UUID
    var name: String
    var deviceTypeRawValue: String
    var roomId: UUID?
    var powerStateRawValue: String
    var connectionStatusRawValue: String
    var lastUpdated: Date
    var isFavorite: Bool
    var sortOrder: Int

    /// デバイス固有のデータを格納（JSON形式）
    /// 例: brightness, colorTemperature, targetTemperature など
    var metadataJSON: String

    // MARK: - Computed Properties

    var deviceType: DeviceType {
        get { DeviceType(rawValue: deviceTypeRawValue) ?? .light }
        set { deviceTypeRawValue = newValue.rawValue }
    }

    var powerState: PowerState {
        get { PowerState(rawValue: powerStateRawValue) ?? .off }
        set { powerStateRawValue = newValue.rawValue }
    }

    var connectionStatus: ConnectionStatus {
        get { ConnectionStatus(rawValue: connectionStatusRawValue) ?? .offline }
        set { connectionStatusRawValue = newValue.rawValue }
    }

    var isOnline: Bool {
        connectionStatus.isConnected
    }

    var isActive: Bool {
        powerState.isActive && isOnline
    }

    /// metadataのディクショナリ形式
    var metadata: [String: String] {
        get {
            guard let data = metadataJSON.data(using: .utf8),
                  let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
                return [:]
            }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let jsonString = String(data: data, encoding: .utf8) {
                metadataJSON = jsonString
            }
        }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        deviceType: DeviceType,
        roomId: UUID? = nil,
        powerState: PowerState = .off,
        connectionStatus: ConnectionStatus = .online,
        isFavorite: Bool = false,
        sortOrder: Int = 0,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.deviceTypeRawValue = deviceType.rawValue
        self.roomId = roomId
        self.powerStateRawValue = powerState.rawValue
        self.connectionStatusRawValue = connectionStatus.rawValue
        self.lastUpdated = Date()
        self.isFavorite = isFavorite
        self.sortOrder = sortOrder

        // metadataをJSON文字列に変換
        if let data = try? JSONEncoder().encode(metadata),
           let jsonString = String(data: data, encoding: .utf8) {
            self.metadataJSON = jsonString
        } else {
            self.metadataJSON = "{}"
        }
    }

    // MARK: - Methods

    /// 電源状態をトグル
    func togglePower() {
        powerState = powerState.toggled
        lastUpdated = Date()
    }

    /// metadataの値を更新
    func updateMetadata(key: String, value: String) {
        var dict = metadata
        dict[key] = value
        metadata = dict
        lastUpdated = Date()
    }

    /// metadataから値を取得
    func getMetadataValue(key: String) -> String? {
        metadata[key]
    }

    /// metadataからInt値を取得
    func getMetadataInt(key: String) -> Int? {
        guard let value = metadata[key] else { return nil }
        return Int(value)
    }

    /// metadataからDouble値を取得
    func getMetadataDouble(key: String) -> Double? {
        guard let value = metadata[key] else { return nil }
        return Double(value)
    }

    /// metadataからBool値を取得
    func getMetadataBool(key: String) -> Bool {
        guard let value = metadata[key] else { return false }
        return value == "true"
    }
}

// MARK: - Metadata Keys

/// デバイス固有のmetadataキー定義
extension SmartDevice {
    enum MetadataKey {
        // 照明
        static let brightness = "brightness"           // 0-100
        static let colorTemperature = "colorTemp"      // 2700-6500K

        // エアコン
        static let targetTemperature = "targetTemp"    // 16-30
        static let acMode = "acMode"                   // ACMode.rawValue
        static let fanSpeed = "fanSpeed"               // FanSpeed.rawValue

        // スピーカー/テレビ
        static let volume = "volume"                   // 0-100
        static let playbackState = "playbackState"    // PlaybackState.rawValue
        static let tvInput = "tvInput"                 // TVInput.rawValue
        static let currentChannel = "channel"          // チャンネル番号

        // カメラ
        static let isRecording = "isRecording"         // "true"/"false"
        static let motionDetected = "motionDetected"   // "true"/"false"

        // スマートロック
        static let lockState = "lockState"             // LockState.rawValue
        static let autoLock = "autoLock"               // "true"/"false"

        // サーモスタット
        static let currentTemperature = "currentTemp"  // 現在の温度
        static let humidity = "humidity"               // 湿度

        // カーテン
        static let openPercentage = "openPercent"      // 0-100
    }
}

// MARK: - Device-Specific Helpers

extension SmartDevice {
    // MARK: - 照明

    /// 照明の明るさ（0-100）
    var brightness: Int {
        get { getMetadataInt(key: MetadataKey.brightness) ?? 100 }
        set { updateMetadata(key: MetadataKey.brightness, value: "\(max(0, min(100, newValue)))") }
    }

    /// 色温度（2700-6500K）
    var colorTemperature: Int {
        get { getMetadataInt(key: MetadataKey.colorTemperature) ?? 4000 }
        set { updateMetadata(key: MetadataKey.colorTemperature, value: "\(max(2700, min(6500, newValue)))") }
    }

    // MARK: - エアコン

    /// 設定温度（16-30）
    var targetTemperature: Int {
        get { getMetadataInt(key: MetadataKey.targetTemperature) ?? 24 }
        set { updateMetadata(key: MetadataKey.targetTemperature, value: "\(max(16, min(30, newValue)))") }
    }

    /// エアコンモード
    var acMode: ACMode {
        get {
            guard let value = getMetadataValue(key: MetadataKey.acMode) else { return .auto }
            return ACMode(rawValue: value) ?? .auto
        }
        set { updateMetadata(key: MetadataKey.acMode, value: newValue.rawValue) }
    }

    /// 風量
    var fanSpeed: FanSpeed {
        get {
            guard let value = getMetadataValue(key: MetadataKey.fanSpeed) else { return .auto }
            return FanSpeed(rawValue: value) ?? .auto
        }
        set { updateMetadata(key: MetadataKey.fanSpeed, value: newValue.rawValue) }
    }

    // MARK: - スピーカー/テレビ共通

    /// 音量（0-100）
    var volume: Int {
        get { getMetadataInt(key: MetadataKey.volume) ?? 50 }
        set { updateMetadata(key: MetadataKey.volume, value: "\(max(0, min(100, newValue)))") }
    }

    /// 再生状態
    var playbackState: PlaybackState {
        get {
            guard let value = getMetadataValue(key: MetadataKey.playbackState) else { return .stopped }
            return PlaybackState(rawValue: value) ?? .stopped
        }
        set { updateMetadata(key: MetadataKey.playbackState, value: newValue.rawValue) }
    }

    // MARK: - テレビ

    /// 入力ソース
    var tvInput: TVInput {
        get {
            guard let value = getMetadataValue(key: MetadataKey.tvInput) else { return .hdmi1 }
            return TVInput(rawValue: value) ?? .hdmi1
        }
        set { updateMetadata(key: MetadataKey.tvInput, value: newValue.rawValue) }
    }

    /// チャンネル
    var currentChannel: Int {
        get { getMetadataInt(key: MetadataKey.currentChannel) ?? 1 }
        set { updateMetadata(key: MetadataKey.currentChannel, value: "\(max(1, newValue))") }
    }

    // MARK: - カメラ

    /// 録画中フラグ
    var isRecording: Bool {
        get { getMetadataBool(key: MetadataKey.isRecording) }
        set { updateMetadata(key: MetadataKey.isRecording, value: newValue ? "true" : "false") }
    }

    /// 動体検知フラグ
    var motionDetected: Bool {
        get { getMetadataBool(key: MetadataKey.motionDetected) }
        set { updateMetadata(key: MetadataKey.motionDetected, value: newValue ? "true" : "false") }
    }

    // MARK: - スマートロック

    /// ロック状態
    var lockState: LockState {
        get {
            guard let value = getMetadataValue(key: MetadataKey.lockState) else { return .locked }
            return LockState(rawValue: value) ?? .locked
        }
        set { updateMetadata(key: MetadataKey.lockState, value: newValue.rawValue) }
    }

    /// 自動ロック設定
    var autoLockEnabled: Bool {
        get { getMetadataBool(key: MetadataKey.autoLock) }
        set { updateMetadata(key: MetadataKey.autoLock, value: newValue ? "true" : "false") }
    }

    // MARK: - サーモスタット

    /// 現在の温度
    var currentTemperature: Double {
        get { getMetadataDouble(key: MetadataKey.currentTemperature) ?? 20.0 }
        set { updateMetadata(key: MetadataKey.currentTemperature, value: String(format: "%.1f", newValue)) }
    }

    /// 湿度（0-100%）
    var humidity: Int {
        get { getMetadataInt(key: MetadataKey.humidity) ?? 50 }
        set { updateMetadata(key: MetadataKey.humidity, value: "\(max(0, min(100, newValue)))") }
    }

    // MARK: - カーテン

    /// 開度（0-100%）
    var openPercentage: Int {
        get { getMetadataInt(key: MetadataKey.openPercentage) ?? 0 }
        set { updateMetadata(key: MetadataKey.openPercentage, value: "\(max(0, min(100, newValue)))") }
    }
}
