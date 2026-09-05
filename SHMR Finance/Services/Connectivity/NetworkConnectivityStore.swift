//
//  NetworkConnectivityStore.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 01.08.2026.
//

import Foundation
import Network
import Observation

private enum NetworkConnectivityStatus: Equatable {
    case unknown
    case connected
    case disconnected
}

private enum Constants {
    static let monitorQueueLabel =
        "com.andreikovryzhenko.shmr-finance.network-monitor"
}

@MainActor
@Observable
final class NetworkConnectivityStore {
    private var status: NetworkConnectivityStatus = .unknown
    private(set) var recoveryGeneration = 0

    var isDisconnected: Bool {
        status == .disconnected
    }

    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(
        label: Constants.monitorQueueLabel
    )

    init(monitor: NWPathMonitor = NWPathMonitor()) {
        self.monitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            Task { @MainActor [weak self] in
                self?.updateAvailability(isConnected: isConnected)
            }
        }
        monitor.start(queue: monitorQueue)
    }

    deinit {
        monitor.cancel()
    }

    private func updateAvailability(isConnected: Bool) {
        let newStatus: NetworkConnectivityStatus = isConnected
            ? .connected
            : .disconnected

        if status == .disconnected,
           newStatus == .connected {
            recoveryGeneration &+= 1
        }

        status = newStatus
    }
}
