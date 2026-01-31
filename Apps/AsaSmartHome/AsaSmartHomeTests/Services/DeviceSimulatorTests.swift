import Testing
import Foundation
@testable import AsaSmartHome

// MARK: - DeviceSimulatorTests

@Suite("DeviceSimulator Tests")
struct DeviceSimulatorTests {

    // MARK: - Properties

    let simulator = DeviceSimulator(simulationDelay: 0.01, failureRate: 0.0)

    // MARK: - Command Execution Tests

    @Test("電源ONコマンドの実行")
    func testExecutePowerOnCommand() async throws {
        let device = SmartDevice(name: "テスト照明", deviceType: .light, powerState: .off, connectionStatus: .online)
        let command = DeviceCommand.power(true)

        let updatedDevice = try await simulator.executeCommand(device: device, command: command)

        #expect(updatedDevice.powerState == .on)
    }

    @Test("電源OFFコマンドの実行")
    func testExecutePowerOffCommand() async throws {
        let device = SmartDevice(name: "テスト照明", deviceType: .light, powerState: .on, connectionStatus: .online)
        let command = DeviceCommand.power(false)

        let updatedDevice = try await simulator.executeCommand(device: device, command: command)

        #expect(updatedDevice.powerState == .off)
    }

    @Test("明るさ設定コマンドの実行")
    func testExecuteBrightnessCommand() async throws {
        let device = SmartDevice(name: "テスト照明", deviceType: .light, connectionStatus: .online)
        let command = DeviceCommand.brightness(75)

        let updatedDevice = try await simulator.executeCommand(device: device, command: command)

        #expect(updatedDevice.brightness == 75)
    }

    @Test("設定温度コマンドの実行")
    func testExecuteTemperatureCommand() async throws {
        let device = SmartDevice(name: "エアコン", deviceType: .airConditioner, connectionStatus: .online)
        let command = DeviceCommand.targetTemperature(26)

        let updatedDevice = try await simulator.executeCommand(device: device, command: command)

        #expect(updatedDevice.targetTemperature == 26)
    }

    @Test("エアコンモードコマンドの実行")
    func testExecuteACModeCommand() async throws {
        let device = SmartDevice(name: "エアコン", deviceType: .airConditioner, connectionStatus: .online)
        let command = DeviceCommand.acMode(.heat)

        let updatedDevice = try await simulator.executeCommand(device: device, command: command)

        #expect(updatedDevice.acMode == .heat)
    }

    @Test("音量コマンドの実行")
    func testExecuteVolumeCommand() async throws {
        let device = SmartDevice(name: "スピーカー", deviceType: .speaker, connectionStatus: .online)
        let command = DeviceCommand.volume(60)

        let updatedDevice = try await simulator.executeCommand(device: device, command: command)

        #expect(updatedDevice.volume == 60)
    }

    @Test("ロック状態コマンドの実行")
    func testExecuteLockStateCommand() async throws {
        let device = SmartDevice(name: "ロック", deviceType: .smartLock, connectionStatus: .online)
        let command = DeviceCommand.lockState(.unlocked)

        let updatedDevice = try await simulator.executeCommand(device: device, command: command)

        #expect(updatedDevice.lockState == .unlocked)
    }

    @Test("カーテン開度コマンドの実行")
    func testExecuteOpenPercentageCommand() async throws {
        let device = SmartDevice(name: "カーテン", deviceType: .curtain, connectionStatus: .online)
        let command = DeviceCommand.openPercentage(50)

        let updatedDevice = try await simulator.executeCommand(device: device, command: command)

        #expect(updatedDevice.openPercentage == 50)
    }

    // MARK: - Error Handling Tests

    @Test("オフラインデバイスへのコマンドはエラー")
    func testCommandToOfflineDeviceFails() async throws {
        let device = SmartDevice(name: "テスト", deviceType: .light, connectionStatus: .offline)
        let command = DeviceCommand.power(true)

        await #expect(throws: SmartHomeServiceError.self) {
            _ = try await simulator.executeCommand(device: device, command: command)
        }
    }

    // MARK: - Sample Data Generation Tests

    @Test("サンプルデバイスの生成")
    func testGenerateSampleDevices() {
        let rooms = Room.sampleRooms()
        let devices = DeviceSimulator.generateSampleDevices(rooms: rooms)

        // デバイスが生成されていることを確認
        #expect(!devices.isEmpty)

        // 複数のデバイスタイプが含まれていることを確認
        let deviceTypes = Set(devices.map { $0.deviceType })
        #expect(deviceTypes.count > 3)
    }

    @Test("空の部屋リストではデバイスが生成されない")
    func testGenerateSampleDevicesWithEmptyRooms() {
        let devices = DeviceSimulator.generateSampleDevices(rooms: [])

        #expect(devices.isEmpty)
    }

    // MARK: - Environment Simulation Tests

    @Test("環境センサー値のシミュレート")
    func testSimulateEnvironmentReading() {
        let reading = simulator.simulateEnvironmentReading()

        #expect(reading.temperature >= 18.0)
        #expect(reading.temperature <= 28.0)
        #expect(reading.humidity >= 30)
        #expect(reading.humidity <= 70)
    }

    @Test("接続状態のシミュレート")
    func testSimulateConnectionStatus() {
        // 100回実行して、ほとんどがonlineであることを確認
        var onlineCount = 0
        for _ in 0..<100 {
            if simulator.simulateConnectionStatus() == .online {
                onlineCount += 1
            }
        }

        // 90%以上がonlineであるべき
        #expect(onlineCount >= 90)
    }
}

// MARK: - DeviceCommand Tests

@Suite("DeviceCommand Tests")
struct DeviceCommandTests {

    @Test("電源コマンドの作成")
    func testPowerCommand() {
        let commandOn = DeviceCommand.power(true)
        let commandOff = DeviceCommand.power(false)

        #expect(commandOn.commandType == .power)
        #expect(commandOn.value.boolValue == true)
        #expect(commandOff.value.boolValue == false)
    }

    @Test("明るさコマンドの作成")
    func testBrightnessCommand() {
        let command = DeviceCommand.brightness(80)

        #expect(command.commandType == .brightness)
        #expect(command.value.intValue == 80)
    }

    @Test("エアコンモードコマンドの作成")
    func testACModeCommand() {
        let command = DeviceCommand.acMode(.cool)

        #expect(command.commandType == .acMode)
        #expect(command.value.stringValue == "cool")
    }

    @Test("CommandValueの変換")
    func testCommandValueConversion() {
        let boolValue = DeviceCommand.CommandValue.bool(true)
        let intValue = DeviceCommand.CommandValue.int(42)
        let stringValue = DeviceCommand.CommandValue.string("test")

        #expect(boolValue.stringValue == "true")
        #expect(intValue.stringValue == "42")
        #expect(stringValue.stringValue == "test")

        #expect(boolValue.intValue == 1)
        #expect(intValue.intValue == 42)
    }
}
