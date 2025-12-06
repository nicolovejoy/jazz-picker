//
//  NetworkMonitor.swift
//  JazzPicker
//

import Foundation
import Network

@Observable
final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private(set) var isConnected: Bool = true
    private(set) var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi
        case cellular
        case wired
        case unknown
    }

    init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }

    private func stopMonitoring() {
        monitor.cancel()
    }

    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wired
        }
        return .unknown
    }
}
