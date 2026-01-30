import Foundation
import Network

// MARK: - NetworkMonitor

@Observable
@MainActor
final class NetworkMonitor {
    // MARK: - Properties

    private(set) var isConnected: Bool = true
    private(set) var connectionType: NWInterface.InterfaceType?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    // MARK: - Computed Properties

    var connectionDescription: String {
        guard isConnected else { return "オフライン" }

        switch connectionType {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return "モバイル通信"
        case .wiredEthernet:
            return "有線接続"
        default:
            return "接続中"
        }
    }

    // MARK: - Initialization

    init() {
        startMonitoring()
    }

    deinit {
        // Note: monitor.cancel()はスレッドセーフなので直接呼び出し可能
        monitor.cancel()
    }

    // MARK: - Public Methods

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied

                // 接続タイプを判定
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .wiredEthernet
                } else {
                    self?.connectionType = nil
                }
            }
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }
}
