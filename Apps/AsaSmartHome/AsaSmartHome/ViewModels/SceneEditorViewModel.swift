import Foundation

// MARK: - SceneEditorViewModel

/// シーン編集用ViewModel
@MainActor
@Observable
final class SceneEditorViewModel {
    // MARK: - Properties

    private let service: SmartHomeServiceProtocol
    private var existingScene: SmartScene?

    // 編集中のデータ
    var name: String = ""
    var iconName: String = "star.fill"
    var colorHex: String = "C68C53"
    var actions: [SceneAction] = []

    // 状態
    private(set) var availableDevices: [SmartDevice] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    // バリデーション
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isEditing: Bool {
        existingScene != nil
    }

    // MARK: - Icon Options

    static let availableIcons: [String] = [
        "star.fill",
        "moon.stars.fill",
        "sun.max.fill",
        "house.fill",
        "figure.walk",
        "play.tv.fill",
        "bed.double.fill",
        "cup.and.saucer.fill",
        "book.fill",
        "gamecontroller.fill",
        "party.popper.fill",
        "sparkles"
    ]

    static let availableColors: [String] = [
        "C68C53",  // AsaCoffeeBrown
        "8B5A2B",  // AsaMocha
        "5E5CE6",  // Purple
        "FF9F0A",  // Orange
        "30D158",  // Green
        "BF5AF2",  // Violet
        "FF375F",  // Red
        "64D2FF"   // Cyan
    ]

    // MARK: - Initialization

    init(service: SmartHomeServiceProtocol, scene: SmartScene? = nil) {
        self.service = service
        self.existingScene = scene

        if let scene = scene {
            self.name = scene.name
            self.iconName = scene.iconName
            self.colorHex = scene.colorHex
            self.actions = scene.actions
        }
    }

    // MARK: - Public Methods

    /// デバイス一覧を読み込み
    func loadDevices() async {
        isLoading = true
        do {
            availableDevices = try await service.fetchDevices()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// アクションを追加
    func addAction(deviceId: UUID, commandType: String, value: String) {
        let action = SceneAction(
            deviceId: deviceId,
            commandType: commandType,
            value: value
        )
        actions.append(action)
    }

    /// アクションを更新
    func updateAction(at index: Int, value: String) {
        guard index < actions.count else { return }
        var action = actions[index]
        action = SceneAction(
            id: action.id,
            deviceId: action.deviceId,
            commandType: action.commandType,
            value: value
        )
        actions[index] = action
    }

    /// アクションを削除
    func removeAction(at index: Int) {
        guard index < actions.count else { return }
        actions.remove(at: index)
    }

    /// デバイスのアクションを削除
    func removeActions(for deviceId: UUID) {
        actions.removeAll { $0.deviceId == deviceId }
    }

    /// シーンを保存
    func save() async throws -> SmartScene {
        isLoading = true
        defer { isLoading = false }

        if let existingScene = existingScene {
            // 既存シーンを更新
            existingScene.name = name
            existingScene.iconName = iconName
            existingScene.colorHex = colorHex
            existingScene.actions = actions
            return try await service.updateSmartScene(existingScene)
        } else {
            // 新規シーンを作成
            let scene = SmartScene(
                name: name,
                iconName: iconName,
                colorHex: colorHex,
                actions: actions
            )
            return try await service.addSmartScene(scene)
        }
    }

    // MARK: - Helper Methods

    /// デバイス名を取得
    func deviceName(for deviceId: UUID) -> String {
        availableDevices.first { $0.id == deviceId }?.name ?? "不明なデバイス"
    }

    /// デバイスを取得
    func device(for deviceId: UUID) -> SmartDevice? {
        availableDevices.first { $0.id == deviceId }
    }

    /// デバイスにアクションがあるかチェック
    func hasAction(for deviceId: UUID) -> Bool {
        actions.contains { $0.deviceId == deviceId }
    }

    /// デバイスのアクションを取得
    func actions(for deviceId: UUID) -> [SceneAction] {
        actions.filter { $0.deviceId == deviceId }
    }
}

// MARK: - Action Templates

extension SceneEditorViewModel {
    /// デバイスタイプに応じた利用可能なアクションタイプ
    func availableCommandTypes(for device: SmartDevice) -> [(type: String, name: String)] {
        switch device.deviceType {
        case .light:
            return [
                ("power", "電源"),
                ("brightness", "明るさ"),
                ("colorTemperature", "色温度")
            ]
        case .airConditioner:
            return [
                ("power", "電源"),
                ("targetTemperature", "温度"),
                ("acMode", "モード"),
                ("fanSpeed", "風量")
            ]
        case .speaker:
            return [
                ("power", "電源"),
                ("volume", "音量"),
                ("playbackState", "再生状態")
            ]
        case .securityCamera:
            return [
                ("power", "電源"),
                ("recording", "録画")
            ]
        case .smartLock:
            return [
                ("lockState", "施錠状態")
            ]
        case .thermostat:
            return [
                ("power", "電源"),
                ("targetTemperature", "温度")
            ]
        case .curtain:
            return [
                ("openPercentage", "開度")
            ]
        case .television:
            return [
                ("power", "電源"),
                ("volume", "音量"),
                ("tvInput", "入力")
            ]
        }
    }

    /// コマンドタイプのデフォルト値
    func defaultValue(for commandType: String, device: SmartDevice) -> String {
        switch commandType {
        case "power":
            return "on"
        case "brightness":
            return "100"
        case "colorTemperature":
            return "4000"
        case "targetTemperature":
            return "24"
        case "acMode":
            return ACMode.auto.rawValue
        case "fanSpeed":
            return FanSpeed.auto.rawValue
        case "volume":
            return "50"
        case "playbackState":
            return PlaybackState.playing.rawValue
        case "recording":
            return "true"
        case "lockState":
            return LockState.locked.rawValue
        case "openPercentage":
            return "100"
        case "tvInput":
            return TVInput.hdmi1.rawValue
        default:
            return ""
        }
    }
}
