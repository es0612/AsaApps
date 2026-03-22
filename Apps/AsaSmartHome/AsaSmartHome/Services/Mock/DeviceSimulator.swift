import Foundation

// MARK: - DeviceSimulator

/// デバイス動作をシミュレートするユーティリティ
/// 実際のIoTハードウェアなしでデバイス操作を模擬
final class DeviceSimulator: @unchecked Sendable {
    // MARK: - Properties

    private let simulationDelay: TimeInterval
    private let failureRate: Double

    // MARK: - Initialization

    init(simulationDelay: TimeInterval = 0.3, failureRate: Double = 0.0) {
        self.simulationDelay = simulationDelay
        self.failureRate = failureRate
    }

    // MARK: - Command Execution

    /// コマンドを実行してデバイス状態を更新
    func executeCommand(device: SmartDevice, command: DeviceCommand) async throws -> SmartDevice {
        // シミュレーション遅延
        try await Task.sleep(nanoseconds: UInt64(simulationDelay * 1_000_000_000))

        // ランダム失敗（テスト用）
        if Double.random(in: 0...1) < failureRate {
            throw SmartHomeServiceError.commandFailed("シミュレートされたエラー")
        }

        // デバイスがオフラインの場合はエラー
        guard device.isOnline else {
            throw SmartHomeServiceError.commandFailed("デバイスがオフラインです")
        }

        // コマンドタイプに応じて状態を更新
        switch command.commandType {
        case .power:
            device.powerState = command.value.boolValue ? .on : .off

        case .brightness:
            if let value = command.value.intValue {
                device.brightness = value
            }

        case .colorTemperature:
            if let value = command.value.intValue {
                device.colorTemperature = value
            }

        case .targetTemperature:
            if let value = command.value.intValue {
                device.targetTemperature = value
            }

        case .acMode:
            if let mode = ACMode(rawValue: command.value.stringValue) {
                device.acMode = mode
            }

        case .fanSpeed:
            if let speed = FanSpeed(rawValue: command.value.stringValue) {
                device.fanSpeed = speed
            }

        case .volume:
            if let value = command.value.intValue {
                device.volume = value
            }

        case .playbackState:
            if let state = PlaybackState(rawValue: command.value.stringValue) {
                device.playbackState = state
            }

        case .tvInput:
            if let input = TVInput(rawValue: command.value.stringValue) {
                device.tvInput = input
            }

        case .channel:
            if let value = command.value.intValue {
                device.currentChannel = value
            }

        case .lockState:
            if let state = LockState(rawValue: command.value.stringValue) {
                device.lockState = state
            }

        case .autoLock:
            device.autoLockEnabled = command.value.boolValue

        case .recording:
            device.isRecording = command.value.boolValue

        case .openPercentage:
            if let value = command.value.intValue {
                device.openPercentage = value
            }
        }

        device.lastUpdated = Date()
        return device
    }

    // MARK: - State Simulation

    /// 環境センサー値をシミュレート（サーモスタット用）
    func simulateEnvironmentReading() -> (temperature: Double, humidity: Int) {
        let temperature = Double.random(in: 18.0...28.0)
        let humidity = Int.random(in: 30...70)
        return (temperature, humidity)
    }

    /// 動体検知をシミュレート（カメラ用）
    func simulateMotionDetection() -> Bool {
        Double.random(in: 0...1) < 0.1  // 10%の確率で検知
    }

    /// 接続状態をシミュレート
    func simulateConnectionStatus() -> ConnectionStatus {
        let random = Double.random(in: 0...1)
        if random < 0.95 {
            return .online
        } else if random < 0.98 {
            return .connecting
        } else {
            return .offline
        }
    }
}

// MARK: - Sample Data Generator

extension DeviceSimulator {
    /// サンプルデバイスを生成
    static func generateSampleDevices(rooms: [Room]) -> [SmartDevice] {
        guard !rooms.isEmpty else { return [] }

        var devices: [SmartDevice] = []

        // リビング（最初の部屋と仮定）
        if let livingRoom = rooms.first {
            // 照明
            let light = SmartDevice(
                name: "リビング照明",
                deviceType: .light,
                roomId: livingRoom.id,
                powerState: .on,
                connectionStatus: .online,
                isFavorite: true,
                metadata: [
                    SmartDevice.MetadataKey.brightness: "80",
                    SmartDevice.MetadataKey.colorTemperature: "4000"
                ]
            )
            devices.append(light)

            // エアコン
            let ac = SmartDevice(
                name: "リビングエアコン",
                deviceType: .airConditioner,
                roomId: livingRoom.id,
                powerState: .on,
                connectionStatus: .online,
                isFavorite: true,
                metadata: [
                    SmartDevice.MetadataKey.targetTemperature: "24",
                    SmartDevice.MetadataKey.acMode: ACMode.cool.rawValue,
                    SmartDevice.MetadataKey.fanSpeed: FanSpeed.auto.rawValue
                ]
            )
            devices.append(ac)

            // テレビ
            let tv = SmartDevice(
                name: "リビングテレビ",
                deviceType: .television,
                roomId: livingRoom.id,
                powerState: .off,
                connectionStatus: .online,
                isFavorite: true,
                metadata: [
                    SmartDevice.MetadataKey.volume: "50",
                    SmartDevice.MetadataKey.tvInput: TVInput.hdmi1.rawValue,
                    SmartDevice.MetadataKey.currentChannel: "1"
                ]
            )
            devices.append(tv)

            // スピーカー
            let speaker = SmartDevice(
                name: "リビングスピーカー",
                deviceType: .speaker,
                roomId: livingRoom.id,
                powerState: .off,
                connectionStatus: .online,
                metadata: [
                    SmartDevice.MetadataKey.volume: "40",
                    SmartDevice.MetadataKey.playbackState: PlaybackState.stopped.rawValue
                ]
            )
            devices.append(speaker)

            // カーテン
            let curtain = SmartDevice(
                name: "リビングカーテン",
                deviceType: .curtain,
                roomId: livingRoom.id,
                powerState: .on,
                connectionStatus: .online,
                metadata: [
                    SmartDevice.MetadataKey.openPercentage: "100"
                ]
            )
            devices.append(curtain)
        }

        // 寝室（2番目の部屋と仮定）
        if rooms.count > 1 {
            let bedroom = rooms[1]

            // 寝室照明
            let bedroomLight = SmartDevice(
                name: "寝室照明",
                deviceType: .light,
                roomId: bedroom.id,
                powerState: .off,
                connectionStatus: .online,
                metadata: [
                    SmartDevice.MetadataKey.brightness: "50",
                    SmartDevice.MetadataKey.colorTemperature: "2700"
                ]
            )
            devices.append(bedroomLight)

            // 寝室エアコン
            let bedroomAC = SmartDevice(
                name: "寝室エアコン",
                deviceType: .airConditioner,
                roomId: bedroom.id,
                powerState: .off,
                connectionStatus: .online,
                metadata: [
                    SmartDevice.MetadataKey.targetTemperature: "26",
                    SmartDevice.MetadataKey.acMode: ACMode.auto.rawValue,
                    SmartDevice.MetadataKey.fanSpeed: FanSpeed.low.rawValue
                ]
            )
            devices.append(bedroomAC)
        }

        // キッチン（3番目の部屋と仮定）
        if rooms.count > 2 {
            let kitchen = rooms[2]

            // キッチンライト
            let kitchenLight = SmartDevice(
                name: "キッチンライト",
                deviceType: .light,
                roomId: kitchen.id,
                powerState: .on,
                connectionStatus: .online,
                metadata: [
                    SmartDevice.MetadataKey.brightness: "100",
                    SmartDevice.MetadataKey.colorTemperature: "5000"
                ]
            )
            devices.append(kitchenLight)

            // スマート冷蔵庫（温度センサーとして）
            let fridge = SmartDevice(
                name: "スマート冷蔵庫",
                deviceType: .thermostat,
                roomId: kitchen.id,
                powerState: .on,
                connectionStatus: .online,
                metadata: [
                    SmartDevice.MetadataKey.currentTemperature: "3.0",
                    SmartDevice.MetadataKey.targetTemperature: "3",
                    SmartDevice.MetadataKey.humidity: "40"
                ]
            )
            devices.append(fridge)

            // キッチン換気扇
            let ventilator = SmartDevice(
                name: "キッチン換気扇",
                deviceType: .airConditioner,
                roomId: kitchen.id,
                powerState: .off,
                connectionStatus: .online,
                metadata: [
                    SmartDevice.MetadataKey.targetTemperature: "22",
                    SmartDevice.MetadataKey.acMode: ACMode.fan.rawValue,
                    SmartDevice.MetadataKey.fanSpeed: FanSpeed.medium.rawValue
                ]
            )
            devices.append(ventilator)
        }

        // 書斎（4番目の部屋と仮定）
        if rooms.count > 3 {
            let office = rooms[3]

            // 書斎照明
            let officeLight = SmartDevice(
                name: "書斎デスクライト",
                deviceType: .light,
                roomId: office.id,
                powerState: .on,
                connectionStatus: .online,
                metadata: [
                    SmartDevice.MetadataKey.brightness: "100",
                    SmartDevice.MetadataKey.colorTemperature: "5000"
                ]
            )
            devices.append(officeLight)
        }

        // 子供部屋（5番目の部屋と仮定）
        if rooms.count > 4 {
            let kidsRoom = rooms[4]

            // おやすみライト
            let nightLight = SmartDevice(
                name: "おやすみライト",
                deviceType: .light,
                roomId: kidsRoom.id,
                powerState: .off,
                connectionStatus: .online,
                metadata: [
                    SmartDevice.MetadataKey.brightness: "30",
                    SmartDevice.MetadataKey.colorTemperature: "2700"
                ]
            )
            devices.append(nightLight)

            // 子供部屋エアコン
            let kidsAC = SmartDevice(
                name: "子供部屋エアコン",
                deviceType: .airConditioner,
                roomId: kidsRoom.id,
                powerState: .off,
                connectionStatus: .online,
                metadata: [
                    SmartDevice.MetadataKey.targetTemperature: "25",
                    SmartDevice.MetadataKey.acMode: ACMode.auto.rawValue,
                    SmartDevice.MetadataKey.fanSpeed: FanSpeed.low.rawValue
                ]
            )
            devices.append(kidsAC)
        }

        // 玄関（共通）
        if rooms.count > 5 {
            let entrance = rooms[5]

            // スマートロック
            let lock = SmartDevice(
                name: "玄関ドアロック",
                deviceType: .smartLock,
                roomId: entrance.id,
                powerState: .on,
                connectionStatus: .online,
                isFavorite: true,
                metadata: [
                    SmartDevice.MetadataKey.lockState: LockState.locked.rawValue,
                    SmartDevice.MetadataKey.autoLock: "true"
                ]
            )
            devices.append(lock)

            // セキュリティカメラ
            let camera = SmartDevice(
                name: "玄関カメラ",
                deviceType: .securityCamera,
                roomId: entrance.id,
                powerState: .on,
                connectionStatus: .online,
                metadata: [
                    SmartDevice.MetadataKey.isRecording: "true",
                    SmartDevice.MetadataKey.motionDetected: "false"
                ]
            )
            devices.append(camera)
        }

        // サーモスタット（リビングに配置）
        if let livingRoom = rooms.first {
            let thermostat = SmartDevice(
                name: "リビングサーモスタット",
                deviceType: .thermostat,
                roomId: livingRoom.id,
                powerState: .on,
                connectionStatus: .online,
                metadata: [
                    SmartDevice.MetadataKey.currentTemperature: "23.5",
                    SmartDevice.MetadataKey.targetTemperature: "24",
                    SmartDevice.MetadataKey.humidity: "55"
                ]
            )
            devices.append(thermostat)
        }

        return devices
    }
}
