import Foundation
import Network

// MARK: - NetworkMonitor

@MainActor
@Observable
final class NetworkMonitor {
    // MARK: - Singleton

    static let shared = NetworkMonitor()

    // MARK: - Properties

    var isConnected: Bool = true
    var connectionType: ConnectionType = .unknown

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    // MARK: - Types

    enum ConnectionType: String {
        case wifi = "WiFi"
        case cellular = "モバイルデータ"
        case ethernet = "イーサネット"
        case unknown = "不明"
    }

    // MARK: - Initialization

    private init() {
        startMonitoring()
    }

    // MARK: - Monitoring

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied

                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .ethernet
                } else {
                    self?.connectionType = .unknown
                }

                print("NetworkMonitor: Connection status changed - \(path.status == .satisfied ? "Connected" : "Disconnected") (\(self?.connectionType.rawValue ?? "Unknown"))")
            }
        }

        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }
}

// MARK: - NetworkStatusView

import SwiftUI
import AsaUIKit

struct NetworkStatusBanner: View {
    let networkMonitor = NetworkMonitor.shared

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.caption)

                Text("オフラインモードで動作中")
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()

                Text("変更は接続復帰後に同期されます")
                    .font(.caption2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AsaColors.mutedSage.opacity(0.2))
            .foregroundColor(AsaColors.mutedSage)
        }
    }
}
