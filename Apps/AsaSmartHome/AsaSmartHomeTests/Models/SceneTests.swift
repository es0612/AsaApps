import Testing
import Foundation
@testable import AsaSmartHome

// MARK: - SceneTests

@Suite("SmartScene Model Tests")
struct SmartSceneTests {

    // MARK: - Initialization Tests

    @Test("シーンのデフォルト初期化")
    func testDefaultInitialization() {
        let scene = SmartScene(name: "テストシーン")

        #expect(scene.name == "テストシーン")
        #expect(scene.iconName == "star.fill")
        #expect(scene.colorHex == "C68C53")
        #expect(scene.actions.isEmpty)
        #expect(scene.isBuiltIn == false)
    }

    @Test("シーンのカスタム初期化")
    func testCustomInitialization() {
        let actions = [
            SceneAction(deviceId: UUID(), commandType: "power", value: "on"),
            SceneAction(deviceId: UUID(), commandType: "brightness", value: "80")
        ]

        let scene = SmartScene(
            name: "おやすみ",
            iconName: "moon.stars.fill",
            colorHex: "5E5CE6",
            actions: actions,
            isBuiltIn: true
        )

        #expect(scene.name == "おやすみ")
        #expect(scene.iconName == "moon.stars.fill")
        #expect(scene.colorHex == "5E5CE6")
        #expect(scene.actions.count == 2)
        #expect(scene.isBuiltIn == true)
    }

    // MARK: - Action Management Tests

    @Test("アクションの追加")
    func testAddAction() {
        let scene = SmartScene(name: "テスト")
        let deviceId = UUID()

        scene.addAction(SceneAction(deviceId: deviceId, commandType: "power", value: "on"))

        #expect(scene.actions.count == 1)
        #expect(scene.actions.first?.deviceId == deviceId)
        #expect(scene.actions.first?.commandType == "power")
    }

    @Test("アクションの削除")
    func testRemoveAction() {
        let deviceId1 = UUID()
        let deviceId2 = UUID()
        let actions = [
            SceneAction(deviceId: deviceId1, commandType: "power", value: "on"),
            SceneAction(deviceId: deviceId2, commandType: "brightness", value: "50")
        ]

        let scene = SmartScene(name: "テスト", actions: actions)
        scene.removeAction(deviceId: deviceId1)

        #expect(scene.actions.count == 1)
        #expect(scene.actions.first?.deviceId == deviceId2)
    }

    @Test("アクションの更新")
    func testUpdateAction() {
        let deviceId = UUID()
        let action = SceneAction(deviceId: deviceId, commandType: "brightness", value: "50")

        let scene = SmartScene(name: "テスト", actions: [action])

        let updatedAction = SceneAction(deviceId: deviceId, commandType: "brightness", value: "100")
        scene.updateAction(updatedAction)

        #expect(scene.actions.count == 1)
        #expect(scene.actions.first?.value == "100")
    }

    // MARK: - SceneAction Tests

    @Test("アクションの説明文生成 - 電源")
    func testActionDescriptionPower() {
        let action = SceneAction(deviceId: UUID(), commandType: "power", value: "on")
        let description = action.description(deviceName: "リビング照明")

        #expect(description == "リビング照明: 電源ON")
    }

    @Test("アクションの説明文生成 - 明るさ")
    func testActionDescriptionBrightness() {
        let action = SceneAction(deviceId: UUID(), commandType: "brightness", value: "75")
        let description = action.description(deviceName: "リビング照明")

        #expect(description == "リビング照明: 明るさ 75%")
    }

    @Test("アクションの説明文生成 - 温度")
    func testActionDescriptionTemperature() {
        let action = SceneAction(deviceId: UUID(), commandType: "temperature", value: "24")
        let description = action.description(deviceName: "エアコン")

        #expect(description == "エアコン: 24°C")
    }

    @Test("アクションの説明文生成 - ロック状態")
    func testActionDescriptionLockState() {
        let action = SceneAction(deviceId: UUID(), commandType: "lockState", value: "locked")
        let description = action.description(deviceName: "玄関ロック")

        #expect(description == "玄関ロック: 施錠")
    }
}

// MARK: - Preset Scene Tests

@Suite("Preset Scene Tests")
struct PresetSceneTests {

    @Test("おやすみシーンのプリセット")
    func testGoodNightScene() {
        let lightId = UUID()
        let lockId = UUID()

        let deviceIds: [DeviceType: UUID] = [
            .light: lightId,
            .smartLock: lockId
        ]

        let scene = SmartScene.goodNightScene(deviceIds: deviceIds)

        #expect(scene.name == "おやすみ")
        #expect(scene.iconName == "moon.stars.fill")
        #expect(scene.isBuiltIn == true)
        #expect(!scene.actions.isEmpty)
    }

    @Test("おはようシーンのプリセット")
    func testGoodMorningScene() {
        let lightId = UUID()
        let curtainId = UUID()

        let deviceIds: [DeviceType: UUID] = [
            .light: lightId,
            .curtain: curtainId
        ]

        let scene = SmartScene.goodMorningScene(deviceIds: deviceIds)

        #expect(scene.name == "おはよう")
        #expect(scene.iconName == "sun.max.fill")
        #expect(scene.isBuiltIn == true)
    }

    @Test("外出シーンのプリセット")
    func testLeaveHomeScene() {
        let lightId = UUID()
        let acId = UUID()

        let deviceIds: [DeviceType: UUID] = [
            .light: lightId,
            .airConditioner: acId
        ]

        let scene = SmartScene.leaveHomeScene(deviceIds: deviceIds)

        #expect(scene.name == "外出")
        #expect(scene.iconName == "figure.walk")
    }
}
