//
//  AccountsStore.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class AccountsStore {
    // MARK: - Public Properties

    private(set) var accounts: [BankAccount] = []
    private(set) var isLoading = false
    private(set) var isRefreshing = false
    private(set) var loadErrorMessage: String?
    private(set) var errorMessage: String?

    // MARK: - Private Properties

    private let service: any AccountServiceProviding
    @ObservationIgnored
    private var refreshTask: Task<Void, Never>?
    @ObservationIgnored
    private var requestedGeneration = 0
    @ObservationIgnored
    private var isStale = true

    // MARK: - Initializers

    init(service: any AccountServiceProviding) {
        self.service = service
    }

    // MARK: - Public Methods

    func ensureFresh() async {
        guard isStale else {
            return
        }

        startRefreshIfNeeded()
        await waitForRefresh()
    }

    func refresh() async {
        requestNewGeneration()
        startRefreshIfNeeded()

        await waitForRefresh()
    }

    func retry() async {
        await refresh()
    }

    func invalidateAndRefresh() {
        requestNewGeneration()
        startRefreshIfNeeded()
    }

    func dismissError() {
        errorMessage = nil
    }

    func updateBalance(
        for account: BankAccount,
        to newBalance: Decimal
    ) async throws {
        guard newBalance >= .zero else {
            throw AccountsStoreError.negativeBalance
        }

        guard let storedAccount = accounts.first(
            where: { $0.id == account.id }
        ) else {
            throw AccountsStoreError.accountNotFound(account.id)
        }

        var accountToUpdate = storedAccount
        accountToUpdate.balance = newBalance

        let updatedAccount = try await service.updateAccount(
            accountToUpdate
        )
        try Task.checkCancellation()

        if let currentIndex = accounts.firstIndex(
            where: { $0.id == updatedAccount.id }
        ) {
            accounts[currentIndex] = updatedAccount
        } else {
            accounts.append(updatedAccount)
        }

        invalidateAndRefresh()
    }

    // MARK: - Private Methods

    private func requestNewGeneration() {
        requestedGeneration &+= 1
        isStale = true
    }

    private func startRefreshIfNeeded() {
        guard refreshTask == nil else {
            return
        }

        let targetGeneration = requestedGeneration
        let showsInitialLoading = accounts.isEmpty

        refreshTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            await performRefresh(
                targetGeneration: targetGeneration,
                showsInitialLoading: showsInitialLoading
            )
            finishRefresh(
                targetGeneration: targetGeneration
            )
        }
    }

    private func waitForRefresh() async {
        while let refreshTask {
            await refreshTask.value

            if Task.isCancelled {
                return
            }
        }
    }

    private func performRefresh(
        targetGeneration: Int,
        showsInitialLoading: Bool
    ) async {
        errorMessage = nil

        if showsInitialLoading {
            loadErrorMessage = nil
            isLoading = true
            isRefreshing = false
        } else {
            isLoading = false
            isRefreshing = true
        }

        do {
            let loadedAccounts = try await service.getAccounts()
            try Task.checkCancellation()

            accounts = loadedAccounts
            loadErrorMessage = nil
            errorMessage = nil
            isStale = targetGeneration < requestedGeneration
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            if accounts.isEmpty {
                loadErrorMessage = error.localizedDescription
            }
            isStale = true
        }
    }

    private func finishRefresh(
        targetGeneration: Int
    ) {
        refreshTask = nil

        if requestedGeneration > targetGeneration {
            isLoading = accounts.isEmpty
            isRefreshing = !accounts.isEmpty
            startRefreshIfNeeded()
        } else {
            isLoading = false
            isRefreshing = false
        }
    }
}

enum AccountsStoreError: LocalizedError {
    case accountNotFound(Int)
    case negativeBalance

    var errorDescription: String? {
        switch self {
        case .accountNotFound:
            AppLocalization.string(localized: "Не удалось найти выбранный счёт")
        case .negativeBalance:
            AppLocalization.string(localized: "Баланс не может быть отрицательным")
        }
    }
}
