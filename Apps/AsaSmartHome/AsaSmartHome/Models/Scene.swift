import Foundation
import SwiftData

// MARK: - SceneAction

/// シーン内の個別アクション
struct SceneAction: Codable, Sendable, Identifiable {
    var id: UUID = UUID()
    var deviceId: UUID
    var commandType: String  // "power", "brightness", "temperature", etc.
    var value: String        // アクションの値

    /// アクションの説明文を生成
    func description(deviceName: String) -> String {
        switch commandType {
        case "power":
            return "\(deviceName): \(value == "on" ? "電源ON" : "電源OFF")"
        case "brightness":
            return "\(deviceName): 明るさ \(value)%"
        case "temperature":
            return "\(deviceName): \(value)°C"
        case "volume":
            return "\(deviceName): 音量 \(value)%"
        case "openPercentage":
            return "\(deviceName): 開度 \(value)%"
        case "lockState":
            return "\(deviceName): \(value == "locked" ? "施錠" : "解錠")"
        default:
            return "\(deviceName): \(commandType) = \(value)"
        }
    }
}

// MARK: - Scene Model

/// シーンモデル - 複数デバイスの一括操作を定義
@Model
final class SmartScene {
    // MARK: - Properties

    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var actionsJSON: String
    var isBuiltIn: Bool  // プリセットシーンかどうか
    var sortOrder: Int
    var createdAt: Date

    // MARK: - Computed Properties

    /// アクションリスト
    var actions: [SceneAction] {
        get {
            guard let data = actionsJSON.data(using: .utf8),
                  let actions = try? JSONDecoder().decode([SceneAction].self, from: data) else {
                return []
            }
            return actions
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let jsonString = String(data: data, encoding: .utf8) {
                actionsJSON = jsonString
            }
        }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "star.fill",
        colorHex: String = "C68C53",
        actions: [SceneAction] = [],
        isBuiltIn: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
        self.createdAt = Date()

        // actionsをJSON文字列に変換
        if let data = try? JSONEncoder().encode(actions),
           let jsonString = String(data: data, encoding: .utf8) {
            self.actionsJSON = jsonString
        } else {
            self.actionsJSON = "[]"
        }
    }

    // MARK: - Methods

    /// アクションを追加
    func addAction(_ action: SceneAction) {
        var currentActions = actions
        currentActions.append(action)
        actions = currentActions
    }

    /// アクションを削除
    func removeAction(deviceId: UUID) {
        var currentActions = actions
        currentActions.removeAll { $0.deviceId == deviceId }
        actions = currentActions
    }

    /// アクションを更新
    func updateAction(_ action: SceneAction) {
        var currentActions = actions
        if let index = currentActions.firstIndex(where: { $0.deviceId == action.deviceId && $0.commandType == action.commandType }) {
            currentActions[index] = action
        } else {
            currentActions.append(action)
        }
        actions = currentActions
    }
}

// MARK: - Preset Scenes

extension SmartScene {
    /// プリセットシーン - おやすみ
    static func goodNightScene(deviceIds: [DeviceType: UUID]) -> SmartScene {
        var actions: [SceneAction] = []

        // すべての照明をオフ
        if let lightId = deviceIds[.light] {
            actions.append(SceneAction(deviceId: lightId, commandType: "power", value: "off"))
        }

        // テレビをオフ
        if let tvId = deviceIds[.television] {
            actions.append(SceneAction(deviceId: tvId, commandType: "power", value: "off"))
        }

        // カーテンを閉じる
        if let curtainId = deviceIds[.curtain] {
            actions.append(SceneAction(deviceId: curtainId, commandType: "openPercentage", value: "0"))
        }

        // ドアを施錠
        if let lockId = deviceIds[.smartLock] {
            actions.append(SceneAction(deviceId: lockId, commandType: "lockState", value: "locked"))
        }

        return SmartScene(
            name: "おやすみ",
            iconName: "moon.stars.fill",
            colorHex: "5E5CE6",
            actions: actions,
            isBuiltIn: true,
            sortOrder: 0
        )
    }

    /// プリセットシーン - おはよう
    static func goodMorningScene(deviceIds: [DeviceType: UUID]) -> SmartScene {
        var actions: [SceneAction] = []

        // 照明をオン、明るさ100%
        if let lightId = deviceIds[.light] {
            actions.append(SceneAction(deviceId: lightId, commandType: "power", value: "on"))
            actions.append(SceneAction(deviceId: lightId, commandType: "brightness", value: "100"))
        }

        // カーテンを開く
        if let curtainId = deviceIds[.curtain] {
            actions.append(SceneAction(deviceId: curtainId, commandType: "openPercentage", value: "100"))
        }

        return SmartScene(
            name: "おはよう",
            iconName: "sun.max.fill",
            colorHex: "FF9F0A",
            actions: actions,
            isBuiltIn: true,
            sortOrder: 1
        )
    }

    /// プリセットシーン - 外出
    static func leaveHomeScene(deviceIds: [DeviceType: UUID]) -> SmartScene {
        var actions: [SceneAction] = []

        // すべての照明をオフ
        if let lightId = deviceIds[.light] {
            actions.append(SceneAction(deviceId: lightId, commandType: "power", value: "off"))
        }

        // エアコンをオフ
        if let acId = deviceIds[.airConditioner] {
            actions.append(SceneAction(deviceId: acId, commandType: "power", value: "off"))
        }

        // テレビをオフ
        if let tvId = deviceIds[.television] {
            actions.append(SceneAction(deviceId: tvId, commandType: "power", value: "off"))
        }

        // ドアを施錠
        if let lockId = deviceIds[.smartLock] {
            actions.append(SceneAction(deviceId: lockId, commandType: "lockState", value: "locked"))
        }

        return SmartScene(
            name: "外出",
            iconName: "figure.walk",
            colorHex: "30D158",
            actions: actions,
            isBuiltIn: true,
            sortOrder: 2
        )
    }

    /// プリセットシーン - 帰宅
    static func comeHomeScene(deviceIds: [DeviceType: UUID]) -> SmartScene {
        var actions: [SceneAction] = []

        // 照明をオン
        if let lightId = deviceIds[.light] {
            actions.append(SceneAction(deviceId: lightId, commandType: "power", value: "on"))
            actions.append(SceneAction(deviceId: lightId, commandType: "brightness", value: "80"))
        }

        // エアコンをオン（自動モード）
        if let acId = deviceIds[.airConditioner] {
            actions.append(SceneAction(deviceId: acId, commandType: "power", value: "on"))
        }

        // ドアを解錠
        if let lockId = deviceIds[.smartLock] {
            actions.append(SceneAction(deviceId: lockId, commandType: "lockState", value: "unlocked"))
        }

        return SmartScene(
            name: "帰宅",
            iconName: "house.fill",
            colorHex: "C68C53",
            actions: actions,
            isBuiltIn: true,
            sortOrder: 3
        )
    }

    /// カスタムシーン - 集中モード
    static func focusScene(deviceIds: [DeviceType: UUID]) -> SmartScene {
        var actions: [SceneAction] = []

        // 書斎ライトを全開
        if let lightId = deviceIds[.light] {
            actions.append(SceneAction(deviceId: lightId, commandType: "power", value: "on"))
            actions.append(SceneAction(deviceId: lightId, commandType: "brightness", value: "100"))
        }

        // テレビをオフ
        if let tvId = deviceIds[.television] {
            actions.append(SceneAction(deviceId: tvId, commandType: "power", value: "off"))
        }

        // スピーカーをオフ
        if let speakerId = deviceIds[.speaker] {
            actions.append(SceneAction(deviceId: speakerId, commandType: "power", value: "off"))
        }

        return SmartScene(
            name: "集中モード",
            iconName: "brain.head.profile.fill",
            colorHex: "64D2FF",
            actions: actions,
            isBuiltIn: false,
            sortOrder: 5
        )
    }

    /// カスタムシーン - お料理タイム
    static func cookingScene(deviceIds: [DeviceType: UUID]) -> SmartScene {
        var actions: [SceneAction] = []

        // キッチンライトをオン
        if let lightId = deviceIds[.light] {
            actions.append(SceneAction(deviceId: lightId, commandType: "power", value: "on"))
            actions.append(SceneAction(deviceId: lightId, commandType: "brightness", value: "100"))
        }

        // スピーカーをオン（BGM用）
        if let speakerId = deviceIds[.speaker] {
            actions.append(SceneAction(deviceId: speakerId, commandType: "power", value: "on"))
            actions.append(SceneAction(deviceId: speakerId, commandType: "volume", value: "30"))
        }

        return SmartScene(
            name: "お料理タイム",
            iconName: "frying.pan.fill",
            colorHex: "FF9F0A",
            actions: actions,
            isBuiltIn: false,
            sortOrder: 6
        )
    }

    /// プリセットシーン - 映画
    static func movieScene(deviceIds: [DeviceType: UUID]) -> SmartScene {
        var actions: [SceneAction] = []

        // 照明を暗くする
        if let lightId = deviceIds[.light] {
            actions.append(SceneAction(deviceId: lightId, commandType: "power", value: "on"))
            actions.append(SceneAction(deviceId: lightId, commandType: "brightness", value: "20"))
        }

        // テレビをオン
        if let tvId = deviceIds[.television] {
            actions.append(SceneAction(deviceId: tvId, commandType: "power", value: "on"))
            actions.append(SceneAction(deviceId: tvId, commandType: "volume", value: "60"))
        }

        // カーテンを閉じる
        if let curtainId = deviceIds[.curtain] {
            actions.append(SceneAction(deviceId: curtainId, commandType: "openPercentage", value: "0"))
        }

        return SmartScene(
            name: "映画モード",
            iconName: "play.tv.fill",
            colorHex: "BF5AF2",
            actions: actions,
            isBuiltIn: true,
            sortOrder: 4
        )
    }
}
