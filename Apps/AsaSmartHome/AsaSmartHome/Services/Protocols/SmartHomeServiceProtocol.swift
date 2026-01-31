import Foundation

// MARK: - SmartHomeServiceProtocol

/// スマートホームサービスのプロトコル
/// 実際のIoTサービスとモックサービスで同じインターフェースを使用
@MainActor
protocol SmartHomeServiceProtocol: AnyObject {
    // MARK: - Devices

    /// すべてのデバイスを取得
    func fetchDevices() async throws -> [SmartDevice]

    /// 特定のデバイスを取得
    func fetchDevice(id: UUID) async throws -> SmartDevice?

    /// デバイスにコマンドを送信
    func sendCommand(deviceId: UUID, command: DeviceCommand) async throws -> CommandResult

    /// デバイスを追加
    func addDevice(_ device: SmartDevice) async throws -> SmartDevice

    /// デバイスを更新
    func updateDevice(_ device: SmartDevice) async throws -> SmartDevice

    /// デバイスを削除
    func deleteDevice(id: UUID) async throws

    // MARK: - Rooms

    /// すべての部屋を取得
    func fetchRooms() async throws -> [Room]

    /// 部屋を追加
    func addRoom(_ room: Room) async throws -> Room

    /// 部屋を更新
    func updateRoom(_ room: Room) async throws -> Room

    /// 部屋を削除
    func deleteRoom(id: UUID) async throws

    // MARK: - SmartScenes

    /// すべてのシーンを取得
    func fetchSmartScenes() async throws -> [SmartScene]

    /// シーンを実行
    func executeSmartScene(id: UUID) async throws -> [CommandResult]

    /// シーンを追加
    func addSmartScene(_ scene: SmartScene) async throws -> SmartScene

    /// シーンを更新
    func updateSmartScene(_ scene: SmartScene) async throws -> SmartScene

    /// シーンを削除
    func deleteSmartScene(id: UUID) async throws

    // MARK: - Schedules

    /// すべてのスケジュールを取得
    func fetchSchedules() async throws -> [Schedule]

    /// スケジュールを追加
    func addSchedule(_ schedule: Schedule) async throws -> Schedule

    /// スケジュールを更新
    func updateSchedule(_ schedule: Schedule) async throws -> Schedule

    /// スケジュールを削除
    func deleteSchedule(id: UUID) async throws

    // MARK: - Real-time Updates

    /// デバイス状態変更のコールバックを設定
    func observeDeviceChanges(handler: @escaping @Sendable ([SmartDevice]) -> Void) -> ObservationToken

    /// 接続状態変更のコールバックを設定
    func observeConnectionStatus(handler: @escaping @Sendable (Bool) -> Void) -> ObservationToken
}

// MARK: - ObservationToken

/// リアルタイム監視のトークン（解除用）
final class ObservationToken: @unchecked Sendable {
    private let onCancel: () -> Void

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() {
        onCancel()
    }

    deinit {
        cancel()
    }
}

// MARK: - SmartHomeServiceError

/// サービスエラー
enum SmartHomeServiceError: Error, LocalizedError {
    case deviceNotFound(UUID)
    case roomNotFound(UUID)
    case sceneNotFound(UUID)
    case scheduleNotFound(UUID)
    case commandFailed(String)
    case networkError
    case dataError(String)

    var errorDescription: String? {
        switch self {
        case .deviceNotFound(let id):
            return "デバイスが見つかりません: \(id)"
        case .roomNotFound(let id):
            return "部屋が見つかりません: \(id)"
        case .sceneNotFound(let id):
            return "シーンが見つかりません: \(id)"
        case .scheduleNotFound(let id):
            return "スケジュールが見つかりません: \(id)"
        case .commandFailed(let message):
            return "コマンド実行失敗: \(message)"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .dataError(let message):
            return "データエラー: \(message)"
        }
    }
}
