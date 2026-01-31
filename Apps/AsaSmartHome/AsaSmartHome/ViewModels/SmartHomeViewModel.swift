import Foundation
import SwiftData

// MARK: - SmartHomeAppState

/// アプリケーションの状態
enum SmartHomeAppState: Sendable {
    case loading
    case ready
    case error(String)
}

// MARK: - SmartHomeViewModel

/// スマートホームアプリのメインViewModel
@MainActor
@Observable
final class SmartHomeViewModel {
    // MARK: - Properties

    private let service: SmartHomeServiceProtocol
    private var deviceObserverToken: ObservationToken?
    private var connectionObserverToken: ObservationToken?

    // 状態
    private(set) var appState: SmartHomeAppState = .loading
    private(set) var isConnected: Bool = true

    // データ
    private(set) var devices: [SmartDevice] = []
    private(set) var rooms: [Room] = []
    private(set) var scenes: [SmartScene] = []
    private(set) var schedules: [Schedule] = []

    // 選択状態
    var selectedRoomId: UUID?

    // MARK: - Computed Properties

    /// お気に入りデバイス
    var favoriteDevices: [SmartDevice] {
        devices.filter { $0.isFavorite }
    }

    /// アクティブなデバイス数
    var activeDeviceCount: Int {
        devices.filter { $0.isActive }.count
    }

    /// オンラインデバイス数
    var onlineDeviceCount: Int {
        devices.filter { $0.isOnline }.count
    }

    /// デバイスタイプ別のカウント
    var deviceCountByType: [DeviceType: Int] {
        var counts: [DeviceType: Int] = [:]
        for device in devices {
            counts[device.deviceType, default: 0] += 1
        }
        return counts
    }

    /// 選択中の部屋のデバイス
    var devicesInSelectedRoom: [SmartDevice] {
        guard let roomId = selectedRoomId else { return devices }
        return devices.filter { $0.roomId == roomId }
    }

    /// 部屋別デバイスマップ
    var devicesByRoom: [UUID: [SmartDevice]] {
        Dictionary(grouping: devices.filter { $0.roomId != nil }) { $0.roomId! }
    }

    /// 部屋に紐付いていないデバイス
    var unassignedDevices: [SmartDevice] {
        devices.filter { $0.roomId == nil }
    }

    // MARK: - Initialization

    init(service: SmartHomeServiceProtocol) {
        self.service = service
    }

    // Note: Tokens are cleaned up automatically by their deinit

    // MARK: - Public Methods

    /// 初期化処理
    func initialize() async {
        appState = .loading

        do {
            // モックサービスの初期データをセットアップ
            if let mockService = service as? MockSmartHomeService {
                try await mockService.setupInitialDataIfNeeded()
            }

            // データを読み込み
            async let roomsTask = service.fetchRooms()
            async let devicesTask = service.fetchDevices()
            async let scenesTask = service.fetchSmartScenes()
            async let schedulesTask = service.fetchSchedules()

            rooms = try await roomsTask
            devices = try await devicesTask
            scenes = try await scenesTask
            schedules = try await schedulesTask

            // オブザーバーを設定
            setupObservers()

            appState = .ready
        } catch {
            appState = .error(error.localizedDescription)
        }
    }

    /// デバイスの電源をトグル
    func toggleDevice(_ device: SmartDevice) async {
        let command = DeviceCommand.power(!device.powerState.isActive)
        await sendCommand(to: device, command: command)
    }

    /// デバイスにコマンドを送信
    func sendCommand(to device: SmartDevice, command: DeviceCommand) async {
        do {
            _ = try await service.sendCommand(deviceId: device.id, command: command)
            await refreshDevices()
        } catch {
            print("Command failed: \(error)")
        }
    }

    /// シーンを実行
    func executeSmartScene(_ scene: SmartScene) async {
        do {
            _ = try await service.executeSmartScene(id: scene.id)
            await refreshDevices()
        } catch {
            print("SmartScene execution failed: \(error)")
        }
    }

    /// デバイスのお気に入りをトグル
    func toggleFavorite(_ device: SmartDevice) async {
        device.isFavorite.toggle()
        do {
            _ = try await service.updateDevice(device)
            await refreshDevices()
        } catch {
            print("Failed to update favorite: \(error)")
        }
    }

    /// データをリフレッシュ
    func refreshDevices() async {
        do {
            devices = try await service.fetchDevices()
        } catch {
            print("Failed to refresh devices: \(error)")
        }
    }

    func refreshRooms() async {
        do {
            rooms = try await service.fetchRooms()
        } catch {
            print("Failed to refresh rooms: \(error)")
        }
    }

    func refreshSmartScenes() async {
        do {
            scenes = try await service.fetchSmartScenes()
        } catch {
            print("Failed to refresh scenes: \(error)")
        }
    }

    func refreshSchedules() async {
        do {
            schedules = try await service.fetchSchedules()
        } catch {
            print("Failed to refresh schedules: \(error)")
        }
    }

    /// 部屋を追加
    func addRoom(_ room: Room) async throws {
        _ = try await service.addRoom(room)
        await refreshRooms()
    }

    /// 部屋を削除
    func deleteRoom(_ room: Room) async throws {
        try await service.deleteRoom(id: room.id)
        await refreshRooms()
    }

    /// シーンを追加
    func addSmartScene(_ scene: SmartScene) async throws {
        _ = try await service.addSmartScene(scene)
        await refreshSmartScenes()
    }

    /// シーンを更新
    func updateSmartScene(_ scene: SmartScene) async throws {
        _ = try await service.updateSmartScene(scene)
        await refreshSmartScenes()
    }

    /// シーンを削除
    func deleteSmartScene(_ scene: SmartScene) async throws {
        try await service.deleteSmartScene(id: scene.id)
        await refreshSmartScenes()
    }

    /// スケジュールを追加
    func addSchedule(_ schedule: Schedule) async throws {
        _ = try await service.addSchedule(schedule)
        await refreshSchedules()
    }

    /// スケジュールを更新
    func updateSchedule(_ schedule: Schedule) async throws {
        _ = try await service.updateSchedule(schedule)
        await refreshSchedules()
    }

    /// スケジュールを削除
    func deleteSchedule(_ schedule: Schedule) async throws {
        try await service.deleteSchedule(id: schedule.id)
        await refreshSchedules()
    }

    // MARK: - Helper Methods

    /// 部屋を取得
    func room(for roomId: UUID) -> Room? {
        rooms.first { $0.id == roomId }
    }

    /// シーンを取得
    func scene(for sceneId: UUID) -> SmartScene? {
        scenes.first { $0.id == sceneId }
    }

    /// デバイスタイプでフィルタ
    func devices(ofType type: DeviceType) -> [SmartDevice] {
        devices.filter { $0.deviceType == type }
    }

    /// 部屋内のデバイスを取得
    func devices(in room: Room) -> [SmartDevice] {
        devices.filter { $0.roomId == room.id }
    }

    // MARK: - Private Methods

    private func setupObservers() {
        deviceObserverToken = service.observeDeviceChanges { [weak self] devices in
            Task { @MainActor in
                self?.devices = devices
            }
        }

        connectionObserverToken = service.observeConnectionStatus { [weak self] isConnected in
            Task { @MainActor in
                self?.isConnected = isConnected
            }
        }
    }
}
