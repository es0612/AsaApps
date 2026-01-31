import Testing
import Foundation
@testable import AsaSmartHome

// MARK: - SmartDeviceTests

@Suite("SmartDevice Model Tests")
struct SmartDeviceTests {

    // MARK: - Initialization Tests

    @Test("デフォルト初期化")
    func testDefaultInitialization() {
        let device = SmartDevice(
            name: "テスト照明",
            deviceType: .light
        )

        #expect(device.name == "テスト照明")
        #expect(device.deviceType == .light)
        #expect(device.powerState == .off)
        #expect(device.connectionStatus == .online)
        #expect(device.isFavorite == false)
    }

    @Test("カスタム初期化")
    func testCustomInitialization() {
        let device = SmartDevice(
            name: "リビングエアコン",
            deviceType: .airConditioner,
            powerState: .on,
            connectionStatus: .online,
            isFavorite: true,
            metadata: [
                SmartDevice.MetadataKey.targetTemperature: "24",
                SmartDevice.MetadataKey.acMode: ACMode.cool.rawValue
            ]
        )

        #expect(device.name == "リビングエアコン")
        #expect(device.deviceType == .airConditioner)
        #expect(device.powerState == .on)
        #expect(device.isFavorite == true)
        #expect(device.targetTemperature == 24)
        #expect(device.acMode == .cool)
    }

    // MARK: - Power State Tests

    @Test("電源トグル - オフからオン")
    func testTogglePowerOffToOn() {
        let device = SmartDevice(name: "テスト", deviceType: .light, powerState: .off)
        device.togglePower()

        #expect(device.powerState == .on)
    }

    @Test("電源トグル - オンからオフ")
    func testTogglePowerOnToOff() {
        let device = SmartDevice(name: "テスト", deviceType: .light, powerState: .on)
        device.togglePower()

        #expect(device.powerState == .off)
    }

    // MARK: - Metadata Tests

    @Test("照明の明るさ設定")
    func testLightBrightness() {
        let device = SmartDevice(name: "照明", deviceType: .light)

        device.brightness = 75
        #expect(device.brightness == 75)

        // 範囲外の値は制限される
        device.brightness = 150
        #expect(device.brightness == 100)

        device.brightness = -10
        #expect(device.brightness == 0)
    }

    @Test("照明の色温度設定")
    func testLightColorTemperature() {
        let device = SmartDevice(name: "照明", deviceType: .light)

        device.colorTemperature = 4000
        #expect(device.colorTemperature == 4000)

        // 範囲外の値は制限される
        device.colorTemperature = 2000
        #expect(device.colorTemperature == 2700)

        device.colorTemperature = 7000
        #expect(device.colorTemperature == 6500)
    }

    @Test("エアコンの設定温度")
    func testACTargetTemperature() {
        let device = SmartDevice(name: "エアコン", deviceType: .airConditioner)

        device.targetTemperature = 24
        #expect(device.targetTemperature == 24)

        // 範囲外の値は制限される
        device.targetTemperature = 10
        #expect(device.targetTemperature == 16)

        device.targetTemperature = 35
        #expect(device.targetTemperature == 30)
    }

    @Test("エアコンモード設定")
    func testACMode() {
        let device = SmartDevice(name: "エアコン", deviceType: .airConditioner)

        device.acMode = .cool
        #expect(device.acMode == .cool)

        device.acMode = .heat
        #expect(device.acMode == .heat)
    }

    @Test("スマートロック状態")
    func testLockState() {
        let device = SmartDevice(name: "ロック", deviceType: .smartLock)

        device.lockState = .locked
        #expect(device.lockState == .locked)
        #expect(device.lockState.isSecure == true)

        device.lockState = .unlocked
        #expect(device.lockState == .unlocked)
        #expect(device.lockState.isSecure == false)
    }

    @Test("カメラ録画状態")
    func testCameraRecording() {
        let device = SmartDevice(name: "カメラ", deviceType: .securityCamera)

        device.isRecording = true
        #expect(device.isRecording == true)

        device.isRecording = false
        #expect(device.isRecording == false)
    }

    @Test("カーテン開度")
    func testCurtainOpenPercentage() {
        let device = SmartDevice(name: "カーテン", deviceType: .curtain)

        device.openPercentage = 50
        #expect(device.openPercentage == 50)

        device.openPercentage = 0
        #expect(device.openPercentage == 0)

        device.openPercentage = 100
        #expect(device.openPercentage == 100)
    }

    // MARK: - Computed Properties Tests

    @Test("isOnline プロパティ")
    func testIsOnline() {
        let device = SmartDevice(name: "テスト", deviceType: .light, connectionStatus: .online)
        #expect(device.isOnline == true)

        device.connectionStatus = .offline
        #expect(device.isOnline == false)
    }

    @Test("isActive プロパティ")
    func testIsActive() {
        let device = SmartDevice(name: "テスト", deviceType: .light, powerState: .on, connectionStatus: .online)
        #expect(device.isActive == true)

        device.powerState = .off
        #expect(device.isActive == false)

        device.powerState = .on
        device.connectionStatus = .offline
        #expect(device.isActive == false)
    }
}

// MARK: - DeviceType Tests

@Suite("DeviceType Tests")
struct DeviceTypeTests {

    @Test("全デバイスタイプの数")
    func testDeviceTypeCount() {
        #expect(DeviceType.allCases.count == 8)
    }

    @Test("デバイスタイプの表示名")
    func testDeviceTypeDisplayName() {
        #expect(DeviceType.light.displayName == "照明")
        #expect(DeviceType.airConditioner.displayName == "エアコン")
        #expect(DeviceType.television.displayName == "テレビ")
    }

    @Test("デバイスタイプのアイコン名")
    func testDeviceTypeIconName() {
        #expect(DeviceType.light.iconName == "lightbulb.fill")
        #expect(DeviceType.smartLock.iconName == "lock.fill")
    }
}

// MARK: - PowerState Tests

@Suite("PowerState Tests")
struct PowerStateTests {

    @Test("電源状態のトグル")
    func testPowerStateToggle() {
        #expect(PowerState.on.toggled == .off)
        #expect(PowerState.off.toggled == .on)
        #expect(PowerState.standby.toggled == .on)
    }

    @Test("電源状態のisActive")
    func testPowerStateIsActive() {
        #expect(PowerState.on.isActive == true)
        #expect(PowerState.off.isActive == false)
        #expect(PowerState.standby.isActive == false)
    }
}
