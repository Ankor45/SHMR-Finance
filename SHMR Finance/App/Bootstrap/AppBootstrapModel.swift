//
//  AppBootstrapModel.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class AppBootstrapModel {
    enum State {
        case idle
        case loading
        case ready(AppDependencies)
        case failed(String)
    }

    private(set) var state: State = .idle

    func start() async {
        guard case .idle = state else {
            return
        }
        await prepareDependencies()
    }

    func retry() async {
        state = .idle
        await start()
    }

    private func prepareDependencies() async {
        state = .loading

        do {
            let environment = try AppEnvironment()
            let dataProvider = try await makeDataProvider(
                for: environment
            )
            let localStorage = try await FinanceStorageMigrator(
                scope: environment.storageScope
            ).prepareStorage()
            let synchronizationStatus = SynchronizationStatusStore()
            let dataSourceStatus = DataSourceStatusStore()
            let networkConnectivity = NetworkConnectivityStore()
            let financeService = FinanceService(
                dataProvider: dataProvider,
                localStorage: localStorage,
                synchronizationStatus: synchronizationStatus,
                dataSourceStatus: dataSourceStatus
            )
            let accountsStore = AccountsStore(service: financeService)

            state = .ready(
                AppDependencies(
                    financeService: financeService,
                    accountsStore: accountsStore,
                    synchronizationStatus: synchronizationStatus,
                    dataSourceStatus: dataSourceStatus,
                    networkConnectivity: networkConnectivity
                )
            )
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func makeDataProvider(
        for environment: AppEnvironment
    ) async throws -> any FinanceDataProviding {
        switch environment {
        case .demo:
            return try await DemoFinanceDataProvider.make()
        case .live:
            let configuration = try APIConfiguration()
            let client = NetworkClient(
                baseURL: configuration.baseURL,
                token: configuration.token
            )
            return NetworkFinanceDataProvider(client: client)
        }
    }
}
