import Foundation
import SwiftData

// MARK: - MockSmartHomeService

/// モックのスマートホームサービス
/// 実際のIoTハードウェアなしでデバイス操作をシミュレート
@MainActor
final class MockSmartHomeService: SmartHomeServiceProtocol {
    // MARK: - Properties

    private let modelContext: ModelContext
    private let simulator: DeviceSimulator
    private var deviceObservers: [(UUID, @Sendable ([SmartDevice]) -> Void)] = []
    private var connectionObservers: [(UUID, @Sendable (Bool) -> Void)] = []
    private var isInitialized = false

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.simulator = DeviceSimulator()
    }

    // MARK: - Setup

    /// 初期データをセットアップ
    func setupInitialDataIfNeeded() async throws {
        guard !isInitialized else { return }

        // 既存データをチェック
        let roomDescriptor = FetchDescriptor<Room>()
        let existingRooms = try modelContext.fetch(roomDescriptor)

        if existingRooms.isEmpty {
            // 部屋を作成
            let rooms = Room.sampleRooms()
            for room in rooms {
                modelContext.insert(room)
            }
            try modelContext.save()

            // デバイスを作成
            let devices = DeviceSimulator.generateSampleDevices(rooms: rooms)
            for device in devices {
                modelContext.insert(device)
            }
            try modelContext.save()

            // プリセットシーンを作成
            let deviceIds = createDeviceIdMap(devices: devices)
            let scenes = [
                SmartScene.goodNightScene(deviceIds: deviceIds),
                SmartScene.goodMorningScene(deviceIds: deviceIds),
                SmartScene.leaveHomeScene(deviceIds: deviceIds),
                SmartScene.comeHomeScene(deviceIds: deviceIds),
                SmartScene.movieScene(deviceIds: deviceIds)
            ]
            for scene in scenes {
                modelContext.insert(scene)
            }
            try modelContext.save()
        }

        isInitialized = true
    }

    private func createDeviceIdMap(devices: [SmartDevice]) -> [DeviceType: UUID] {
        var map: [DeviceType: UUID] = [:]
        for device in devices {
            if map[device.deviceType] == nil {
                map[device.deviceType] = device.id
            }
        }
        return map
    }

    // MARK: - Devices

    func fetchDevices() async throws -> [SmartDevice] {
        let descriptor = FetchDescriptor<SmartDevice>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchDevice(id: UUID) async throws -> SmartDevice? {
        let descriptor = FetchDescriptor<SmartDevice>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func sendCommand(deviceId: UUID, command: DeviceCommand) async throws -> CommandResult {
        guard let device = try await fetchDevice(id: deviceId) else {
            throw SmartHomeServiceError.deviceNotFound(deviceId)
        }

        do {
            let updatedDevice = try await simulator.executeCommand(device: device, command: command)
            try modelContext.save()
            notifyDeviceObservers()
            return .success(device: updatedDevice)
        } catch {
            return .failure(message: error.localizedDescription)
        }
    }

    func addDevice(_ device: SmartDevice) async throws -> SmartDevice {
        modelContext.insert(device)
        try modelContext.save()
        notifyDeviceObservers()
        return device
    }

    func updateDevice(_ device: SmartDevice) async throws -> SmartDevice {
        device.lastUpdated = Date()
        try modelContext.save()
        notifyDeviceObservers()
        return device
    }

    func deleteDevice(id: UUID) async throws {
        guard let device = try await fetchDevice(id: id) else {
            throw SmartHomeServiceError.deviceNotFound(id)
        }
        modelContext.delete(device)
        try modelContext.save()
        notifyDeviceObservers()
    }

    // MARK: - Rooms

    func fetchRooms() async throws -> [Room] {
        let descriptor = FetchDescriptor<Room>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func addRoom(_ room: Room) async throws -> Room {
        modelContext.insert(room)
        try modelContext.save()
        return room
    }

    func updateRoom(_ room: Room) async throws -> Room {
        try modelContext.save()
        return room
    }

    func deleteRoom(id: UUID) async throws {
        let descriptor = FetchDescriptor<Room>(
            predicate: #Predicate { $0.id == id }
        )
        guard let room = try modelContext.fetch(descriptor).first else {
            throw SmartHomeServiceError.roomNotFound(id)
        }
        modelContext.delete(room)
        try modelContext.save()
    }

    // MARK: - SmartScenes

    func fetchSmartScenes() async throws -> [SmartScene] {
        let descriptor = FetchDescriptor<SmartScene>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func executeSmartScene(id: UUID) async throws -> [CommandResult] {
        let descriptor = FetchDescriptor<SmartScene>(
            predicate: #Predicate { $0.id == id }
        )
        guard let scene = try modelContext.fetch(descriptor).first else {
            throw SmartHomeServiceError.sceneNotFound(id)
        }

        var results: [CommandResult] = []

        for action in scene.actions {
            let command = DeviceCommand(
                commandType: DeviceCommand.CommandType(rawValue: action.commandType) ?? .power,
                value: .string(action.value)
            )

            do {
                let result = try await sendCommand(deviceId: action.deviceId, command: command)
                results.append(result)
            } catch {
                results.append(.failure(message: error.localizedDescription))
            }
        }

        return results
    }

    func addSmartScene(_ scene: SmartScene) async throws -> SmartScene {
        modelContext.insert(scene)
        try modelContext.save()
        return scene
    }

    func updateSmartScene(_ scene: SmartScene) async throws -> SmartScene {
        try modelContext.save()
        return scene
    }

    func deleteSmartScene(id: UUID) async throws {
        let descriptor = FetchDescriptor<SmartScene>(
            predicate: #Predicate { $0.id == id }
        )
        guard let scene = try modelContext.fetch(descriptor).first else {
            throw SmartHomeServiceError.sceneNotFound(id)
        }
        modelContext.delete(scene)
        try modelContext.save()
    }

    // MARK: - Schedules

    func fetchSchedules() async throws -> [Schedule] {
        let descriptor = FetchDescriptor<Schedule>(
            sortBy: [SortDescriptor(\.hour), SortDescriptor(\.minute)]
        )
        return try modelContext.fetch(descriptor)
    }

    func addSchedule(_ schedule: Schedule) async throws -> Schedule {
        modelContext.insert(schedule)
        try modelContext.save()
        return schedule
    }

    func updateSchedule(_ schedule: Schedule) async throws -> Schedule {
        try modelContext.save()
        return schedule
    }

    func deleteSchedule(id: UUID) async throws {
        let descriptor = FetchDescriptor<Schedule>(
            predicate: #Predicate { $0.id == id }
        )
        guard let schedule = try modelContext.fetch(descriptor).first else {
            throw SmartHomeServiceError.scheduleNotFound(id)
        }
        modelContext.delete(schedule)
        try modelContext.save()
    }

    // MARK: - Observations

    func observeDeviceChanges(handler: @escaping @Sendable ([SmartDevice]) -> Void) -> ObservationToken {
        let id = UUID()
        deviceObservers.append((id, handler))

        return ObservationToken { [weak self] in
            self?.deviceObservers.removeAll { $0.0 == id }
        }
    }

    func observeConnectionStatus(handler: @escaping @Sendable (Bool) -> Void) -> ObservationToken {
        let id = UUID()
        connectionObservers.append((id, handler))

        // 初期状態を通知
        handler(true)

        return ObservationToken { [weak self] in
            self?.connectionObservers.removeAll { $0.0 == id }
        }
    }

    // MARK: - Private Methods

    private func notifyDeviceObservers() {
        Task { @MainActor in
            do {
                let devices = try await fetchDevices()
                for (_, handler) in deviceObservers {
                    handler(devices)
                }
            } catch {
                print("Failed to notify device observers: \(error)")
            }
        }
    }
}
