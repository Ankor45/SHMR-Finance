//
//  AppDependencies.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

@MainActor
struct AppDependencies {
    let financeService: FinanceService
    let accountsStore: AccountsStore
    let synchronizationStatus: SynchronizationStatusStore
    let dataSourceStatus: DataSourceStatusStore
    let networkConnectivity: NetworkConnectivityStore
}
