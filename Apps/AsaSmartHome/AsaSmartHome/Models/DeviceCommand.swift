import Foundation

// MARK: - DeviceCommand

/// デバイスへのコマンドを表す構造体
struct DeviceCommand: Sendable, Codable {
    let commandType: CommandType
    let value: CommandValue

    enum CommandType: String, Codable, Sendable {
        case power = "power"
        case brightness = "brightness"
        case colorTemperature = "colorTemperature"
        case targetTemperature = "targetTemperature"
        case acMode = "acMode"
        case fanSpeed = "fanSpeed"
        case volume = "volume"
        case playbackState = "playbackState"
        case tvInput = "tvInput"
        case channel = "channel"
        case lockState = "lockState"
        case autoLock = "autoLock"
        case recording = "recording"
        case openPercentage = "openPercentage"
    }

    enum CommandValue: Sendable, Codable {
        case bool(Bool)
        case int(Int)
        case double(Double)
        case string(String)

        var stringValue: String {
            switch self {
            case .bool(let value): return value ? "true" : "false"
            case .int(let value): return "\(value)"
            case .double(let value): return "\(value)"
            case .string(let value): return value
            }
        }

        var intValue: Int? {
            switch self {
            case .int(let value): return value
            case .double(let value): return Int(value)
            case .string(let value): return Int(value)
            case .bool(let value): return value ? 1 : 0
            }
        }

        var boolValue: Bool {
            switch self {
            case .bool(let value): return value
            case .int(let value): return value != 0
            case .double(let value): return value != 0
            case .string(let value): return value == "true" || value == "1"
            }
        }
    }
}

// MARK: - Convenience Initializers

extension DeviceCommand {
    /// 電源ON/OFFコマンド
    static func power(_ isOn: Bool) -> DeviceCommand {
        DeviceCommand(commandType: .power, value: .bool(isOn))
    }

    /// 明るさ設定コマンド (0-100)
    static func brightness(_ value: Int) -> DeviceCommand {
        DeviceCommand(commandType: .brightness, value: .int(value))
    }

    /// 色温度設定コマンド (2700-6500K)
    static func colorTemperature(_ value: Int) -> DeviceCommand {
        DeviceCommand(commandType: .colorTemperature, value: .int(value))
    }

    /// 設定温度コマンド (16-30)
    static func targetTemperature(_ value: Int) -> DeviceCommand {
        DeviceCommand(commandType: .targetTemperature, value: .int(value))
    }

    /// エアコンモード設定コマンド
    static func acMode(_ mode: ACMode) -> DeviceCommand {
        DeviceCommand(commandType: .acMode, value: .string(mode.rawValue))
    }

    /// 風量設定コマンド
    static func fanSpeed(_ speed: FanSpeed) -> DeviceCommand {
        DeviceCommand(commandType: .fanSpeed, value: .string(speed.rawValue))
    }

    /// 音量設定コマンド (0-100)
    static func volume(_ value: Int) -> DeviceCommand {
        DeviceCommand(commandType: .volume, value: .int(value))
    }

    /// 再生状態設定コマンド
    static func playbackState(_ state: PlaybackState) -> DeviceCommand {
        DeviceCommand(commandType: .playbackState, value: .string(state.rawValue))
    }

    /// テレビ入力切替コマンド
    static func tvInput(_ input: TVInput) -> DeviceCommand {
        DeviceCommand(commandType: .tvInput, value: .string(input.rawValue))
    }

    /// チャンネル変更コマンド
    static func channel(_ value: Int) -> DeviceCommand {
        DeviceCommand(commandType: .channel, value: .int(value))
    }

    /// ロック状態変更コマンド
    static func lockState(_ state: LockState) -> DeviceCommand {
        DeviceCommand(commandType: .lockState, value: .string(state.rawValue))
    }

    /// 自動ロック設定コマンド
    static func autoLock(_ enabled: Bool) -> DeviceCommand {
        DeviceCommand(commandType: .autoLock, value: .bool(enabled))
    }

    /// 録画状態変更コマンド
    static func recording(_ enabled: Bool) -> DeviceCommand {
        DeviceCommand(commandType: .recording, value: .bool(enabled))
    }

    /// カーテン開度設定コマンド (0-100)
    static func openPercentage(_ value: Int) -> DeviceCommand {
        DeviceCommand(commandType: .openPercentage, value: .int(value))
    }
}

// MARK: - Command Execution Result

/// コマンド実行結果
@MainActor
struct CommandResult {
    let success: Bool
    let message: String?
    let updatedDevice: SmartDevice?

    static func success(device: SmartDevice? = nil) -> CommandResult {
        CommandResult(success: true, message: nil, updatedDevice: device)
    }

    static func failure(message: String) -> CommandResult {
        CommandResult(success: false, message: message, updatedDevice: nil)
    }
}
