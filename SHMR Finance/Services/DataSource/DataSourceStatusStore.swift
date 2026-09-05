//
//  DataSourceStatusStore.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Observation

nonisolated enum DataSourceResource: Hashable, Sendable {
    case accounts
    case categories
    case transactions(accountId: Int)
}

@MainActor
protocol DataSourceStatusReporting: Sendable {
    func didLoadRemoteData(for resource: DataSourceResource)
    func didLoadLocalData(for resource: DataSourceResource)
}

@MainActor
@Observable
final class DataSourceStatusStore: DataSourceStatusReporting {
    private var localResources: Set<DataSourceResource> = []

    var isUsingLocalData: Bool {
        !localResources.isEmpty
    }

    func didLoadRemoteData(for resource: DataSourceResource) {
        localResources.remove(resource)
    }

    func didLoadLocalData(for resource: DataSourceResource) {
        localResources.insert(resource)
    }
}
