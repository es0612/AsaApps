import Foundation

// MARK: - デバイスタイプ（8種類）

/// スマートホームで制御可能なデバイスの種類
enum DeviceType: String, Codable, CaseIterable, Sendable, Identifiable {
    case light = "light"              // 照明
    case airConditioner = "ac"        // エアコン
    case speaker = "speaker"          // スピーカー
    case securityCamera = "camera"    // セキュリティカメラ
    case smartLock = "lock"           // スマートロック
    case thermostat = "thermostat"    // サーモスタット
    case curtain = "curtain"          // カーテン
    case television = "tv"            // テレビ

    var id: String { rawValue }

    /// デバイスタイプの日本語名
    var displayName: String {
        switch self {
        case .light: return "照明"
        case .airConditioner: return "エアコン"
        case .speaker: return "スピーカー"
        case .securityCamera: return "カメラ"
        case .smartLock: return "スマートロック"
        case .thermostat: return "サーモスタット"
        case .curtain: return "カーテン"
        case .television: return "テレビ"
        }
    }

    /// SF Symbolsアイコン名
    var iconName: String {
        switch self {
        case .light: return "lightbulb.fill"
        case .airConditioner: return "air.conditioner.horizontal.fill"
        case .speaker: return "hifispeaker.fill"
        case .securityCamera: return "video.fill"
        case .smartLock: return "lock.fill"
        case .thermostat: return "thermometer.medium"
        case .curtain: return "blinds.vertical.closed"
        case .television: return "tv.fill"
        }
    }

    /// デバイスオフ時のアイコン名
    var offIconName: String {
        switch self {
        case .light: return "lightbulb"
        case .airConditioner: return "air.conditioner.horizontal"
        case .speaker: return "hifispeaker"
        case .securityCamera: return "video"
        case .smartLock: return "lock.open"
        case .thermostat: return "thermometer.low"
        case .curtain: return "blinds.vertical.open"
        case .television: return "tv"
        }
    }
}

// MARK: - 電源状態

/// デバイスの電源状態
enum PowerState: String, Codable, Sendable {
    case on = "on"
    case off = "off"
    case standby = "standby"  // スタンバイ状態（テレビなど）

    var isActive: Bool {
        self == .on
    }

    /// 状態を切り替える
    var toggled: PowerState {
        switch self {
        case .on: return .off
        case .off, .standby: return .on
        }
    }
}

// MARK: - 接続状態

/// デバイスのネットワーク接続状態
enum ConnectionStatus: String, Codable, Sendable {
    case online = "online"       // オンライン（正常）
    case offline = "offline"     // オフライン（接続なし）
    case connecting = "connecting" // 接続中
    case error = "error"         // エラー

    var isConnected: Bool {
        self == .online
    }

    var displayName: String {
        switch self {
        case .online: return "オンライン"
        case .offline: return "オフライン"
        case .connecting: return "接続中..."
        case .error: return "エラー"
        }
    }

    var iconName: String {
        switch self {
        case .online: return "wifi"
        case .offline: return "wifi.slash"
        case .connecting: return "wifi.exclamationmark"
        case .error: return "exclamationmark.triangle"
        }
    }
}

// MARK: - エアコンモード

/// エアコンの運転モード
enum ACMode: String, Codable, CaseIterable, Sendable {
    case cool = "cool"      // 冷房
    case heat = "heat"      // 暖房
    case dry = "dry"        // 除湿
    case fan = "fan"        // 送風
    case auto = "auto"      // 自動

    var displayName: String {
        switch self {
        case .cool: return "冷房"
        case .heat: return "暖房"
        case .dry: return "除湿"
        case .fan: return "送風"
        case .auto: return "自動"
        }
    }

    var iconName: String {
        switch self {
        case .cool: return "snowflake"
        case .heat: return "sun.max.fill"
        case .dry: return "drop.degreesign"
        case .fan: return "fan.fill"
        case .auto: return "a.circle.fill"
        }
    }
}

// MARK: - 風量

/// エアコンの風量設定
enum FanSpeed: String, Codable, CaseIterable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case auto = "auto"

    var displayName: String {
        switch self {
        case .low: return "弱"
        case .medium: return "中"
        case .high: return "強"
        case .auto: return "自動"
        }
    }
}

// MARK: - ロック状態

/// スマートロックの施錠状態
enum LockState: String, Codable, Sendable {
    case locked = "locked"
    case unlocked = "unlocked"
    case jammed = "jammed"  // 故障・異常

    var isSecure: Bool {
        self == .locked
    }

    var displayName: String {
        switch self {
        case .locked: return "施錠"
        case .unlocked: return "解錠"
        case .jammed: return "異常"
        }
    }

    var iconName: String {
        switch self {
        case .locked: return "lock.fill"
        case .unlocked: return "lock.open.fill"
        case .jammed: return "lock.trianglebadge.exclamationmark"
        }
    }
}

// MARK: - 再生状態

/// スピーカー/テレビの再生状態
enum PlaybackState: String, Codable, Sendable {
    case playing = "playing"
    case paused = "paused"
    case stopped = "stopped"

    var isPlaying: Bool {
        self == .playing
    }

    var iconName: String {
        switch self {
        case .playing: return "play.fill"
        case .paused: return "pause.fill"
        case .stopped: return "stop.fill"
        }
    }
}

// MARK: - テレビ入力

/// テレビの入力ソース
enum TVInput: String, Codable, CaseIterable, Sendable {
    case hdmi1 = "hdmi1"
    case hdmi2 = "hdmi2"
    case hdmi3 = "hdmi3"
    case antenna = "antenna"
    case streaming = "streaming"

    var displayName: String {
        switch self {
        case .hdmi1: return "HDMI 1"
        case .hdmi2: return "HDMI 2"
        case .hdmi3: return "HDMI 3"
        case .antenna: return "アンテナ"
        case .streaming: return "ストリーミング"
        }
    }
}

// MARK: - 部屋タイプ

/// 部屋の種類（アイコン用）
enum RoomType: String, Codable, CaseIterable, Sendable {
    case livingRoom = "living"
    case bedroom = "bedroom"
    case kitchen = "kitchen"
    case bathroom = "bathroom"
    case office = "office"
    case kids = "kids"
    case garage = "garage"
    case outdoor = "outdoor"
    case other = "other"

    var displayName: String {
        switch self {
        case .livingRoom: return "リビング"
        case .bedroom: return "寝室"
        case .kitchen: return "キッチン"
        case .bathroom: return "バスルーム"
        case .office: return "書斎"
        case .kids: return "子供部屋"
        case .garage: return "ガレージ"
        case .outdoor: return "屋外"
        case .other: return "その他"
        }
    }

    var iconName: String {
        switch self {
        case .livingRoom: return "sofa.fill"
        case .bedroom: return "bed.double.fill"
        case .kitchen: return "refrigerator.fill"
        case .bathroom: return "shower.fill"
        case .office: return "desktopcomputer"
        case .kids: return "figure.2.and.child.holdinghands"
        case .garage: return "car.fill"
        case .outdoor: return "tree.fill"
        case .other: return "house.fill"
        }
    }
}
