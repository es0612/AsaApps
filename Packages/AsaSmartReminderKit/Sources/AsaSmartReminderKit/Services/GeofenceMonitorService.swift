#if os(iOS)
import CoreLocation
import Foundation

// MARK: - ジオフェンス監視サービス

/// CLMonitorベースのジオフェンス監視
/// actor で排他制御し、安全なCLMonitorの利用を保証
public actor GeofenceMonitorService: GeofenceMonitoring {
    /// 監視名（固定。CLMonitorの複数生成を防止）
    private static let monitorName = "AsaSmartReminder"

    private var monitor: CLMonitor?
    private var eventTask: Task<Void, any Error>?
    private var monitoredIdentifiers: Set<String> = []

    /// ジオフェンスイベント発生時のコールバック
    public var onEvent: (@Sendable (GeofenceEvent) -> Void)?

    // MARK: - Init

    public init() {}

    // MARK: - ジオフェンスイベント

    public struct GeofenceEvent: Sendable {
        public let identifier: String
        public let state: State

        public enum State: Sendable {
            case entered
            case exited
            case unknown
        }
    }

    // MARK: - 監視開始

    /// CLMonitorを初期化し、イベントストリームを開始
    public func startService() async throws {
        // 既存のmonitorがあれば停止してから再生成
        await stopService()

        let newMonitor = await CLMonitor(GeofenceMonitorService.monitorName)
        self.monitor = newMonitor

        // イベントストリームを購読
        let callback = onEvent
        eventTask = Task {
            for try await event in await newMonitor.events {
                if Task.isCancelled { break }
                let state: GeofenceEvent.State
                switch event.state {
                case .satisfied:
                    state = .entered
                case .unsatisfied:
                    state = .exited
                default:
                    state = .unknown
                }
                callback?(GeofenceEvent(identifier: event.identifier, state: state))
            }
        }
    }

    /// 監視を完全停止（monitorを破棄）
    public func stopService() async {
        eventTask?.cancel()
        eventTask = nil
        monitor = nil
        monitoredIdentifiers.removeAll()
    }

    // MARK: - GeofenceMonitoring プロトコル

    public func startMonitoring(
        identifier: String,
        coordinate: CLLocationCoordinate2D,
        radius: Double
    ) async throws {
        guard let monitor = monitor else {
            throw SmartReminderError.monitoringFailed("CLMonitorが初期化されていません")
        }

        let condition = CLMonitor.CircularGeographicCondition(
            center: coordinate,
            radius: radius
        )
        await monitor.add(condition, identifier: identifier)
        monitoredIdentifiers.insert(identifier)
    }

    public func stopMonitoring(identifier: String) async {
        guard let monitor = monitor else { return }
        await monitor.remove(identifier)
        monitoredIdentifiers.remove(identifier)
    }

    public func stopAllMonitoring() async {
        guard let monitor = monitor else { return }
        for identifier in monitoredIdentifiers {
            await monitor.remove(identifier)
        }
        monitoredIdentifiers.removeAll()
    }

    public var monitoredRegionCount: Int {
        monitoredIdentifiers.count
    }
}
#endif
