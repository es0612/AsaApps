import Foundation

// MARK: - DeviceControlViewModel

/// デバイス個別操作用ViewModel
@MainActor
@Observable
final class DeviceControlViewModel {
    // MARK: - Properties

    private let service: SmartHomeServiceProtocol
    private(set) var device: SmartDevice
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    // MARK: - Initialization

    init(device: SmartDevice, service: SmartHomeServiceProtocol) {
        self.device = device
        self.service = service
    }

    // MARK: - Common Controls

    /// 電源トグル
    func togglePower() async {
        await sendCommand(.power(!device.powerState.isActive))
    }

    /// お気に入りトグル
    func toggleFavorite() async {
        device.isFavorite.toggle()
        do {
            isLoading = true
            device = try await service.updateDevice(device)
        } catch {
            errorMessage = error.localizedDescription
            device.isFavorite.toggle()  // ロールバック
        }
        isLoading = false
    }

    // MARK: - Light Controls

    /// 明るさを設定
    func setBrightness(_ value: Int) async {
        await sendCommand(.brightness(value))
    }

    /// 色温度を設定
    func setColorTemperature(_ value: Int) async {
        await sendCommand(.colorTemperature(value))
    }

    // MARK: - Air Conditioner Controls

    /// 設定温度を変更
    func setTargetTemperature(_ value: Int) async {
        await sendCommand(.targetTemperature(value))
    }

    /// エアコンモードを変更
    func setACMode(_ mode: ACMode) async {
        await sendCommand(.acMode(mode))
    }

    /// 風量を変更
    func setFanSpeed(_ speed: FanSpeed) async {
        await sendCommand(.fanSpeed(speed))
    }

    // MARK: - Speaker/TV Controls

    /// 音量を設定
    func setVolume(_ value: Int) async {
        await sendCommand(.volume(value))
    }

    /// 再生状態を設定
    func setPlaybackState(_ state: PlaybackState) async {
        await sendCommand(.playbackState(state))
    }

    /// テレビ入力を変更
    func setTVInput(_ input: TVInput) async {
        await sendCommand(.tvInput(input))
    }

    /// チャンネルを変更
    func setChannel(_ channel: Int) async {
        await sendCommand(.channel(channel))
    }

    // MARK: - Lock Controls

    /// ロック状態を変更
    func setLockState(_ state: LockState) async {
        await sendCommand(.lockState(state))
    }

    /// 自動ロックを設定
    func setAutoLock(_ enabled: Bool) async {
        await sendCommand(.autoLock(enabled))
    }

    // MARK: - Camera Controls

    /// 録画状態を変更
    func setRecording(_ enabled: Bool) async {
        await sendCommand(.recording(enabled))
    }

    // MARK: - Curtain Controls

    /// カーテン開度を設定
    func setOpenPercentage(_ value: Int) async {
        await sendCommand(.openPercentage(value))
    }

    // MARK: - Private Methods

    private func sendCommand(_ command: DeviceCommand) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await service.sendCommand(deviceId: device.id, command: command)
            if let updatedDevice = result.updatedDevice {
                device = updatedDevice
            } else if !result.success {
                errorMessage = result.message ?? "コマンドの実行に失敗しました"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// デバイス状態をリフレッシュ
    func refresh() async {
        do {
            if let updatedDevice = try await service.fetchDevice(id: device.id) {
                device = updatedDevice
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
