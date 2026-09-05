//
//  FinanceSynchronizer.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation

actor FinanceSynchronizer: FinanceSynchronizing {
    private let dataProvider: any FinanceDataProviding
    private let localStorage: any FinanceLocalStorage
    private let statusReporter: any SynchronizationStatusReporting

    private var synchronizationTask: Task<Void, Error>?
    private var didRepairStorage = false

    init(
        dataProvider: any FinanceDataProviding,
        localStorage: any FinanceLocalStorage,
        statusReporter: any SynchronizationStatusReporting
    ) {
        self.dataProvider = dataProvider
        self.localStorage = localStorage
        self.statusReporter = statusReporter
    }

    func synchronize() async throws {
        if let synchronizationTask {
            try await synchronizationTask.value
            try Task.checkCancellation()
            return
        }

        let task = Task { [self] in
            if !didRepairStorage {
                try await localStorage.repairPendingChanges()
                didRepairStorage = true
            }

            try await synchronizeTransactions()

            let transactionChanges = try await localStorage
                .loadPendingTransactionChanges()
            if transactionChanges.contains(where: { $0.state == .failed }) {
                await reportIssues(
                    transactionChanges: transactionChanges,
                    accountChanges: try await localStorage
                        .loadPendingAccountChanges()
                )
                return
            }

            try await synchronizeAccounts()
            await reportIssues(
                transactionChanges: try await localStorage
                    .loadPendingTransactionChanges(),
                accountChanges: try await localStorage
                    .loadPendingAccountChanges()
            )
        }
        synchronizationTask = task

        defer { synchronizationTask = nil }

        try await task.value
        try Task.checkCancellation()
    }

    private func synchronizeTransactions() async throws {
        let changes = try await localStorage.loadPendingTransactionChanges()

        for change in changes where change.state == .pending {
            try Task.checkCancellation()
            do {
                try await synchronize(change)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                guard Self.shouldQuarantine(change, after: error) else {
                    throw error
                }
                try await localStorage.markPendingTransactionFailed(
                    id: change.transactionId,
                    replacingRevision: change.revision,
                    message: Self.errorMessage(from: error)
                )
            }
        }
    }

    private func synchronizeAccounts() async throws {
        let changes = try await localStorage.loadPendingAccountChanges()

        for change in changes where change.state == .pending {
            try Task.checkCancellation()
            do {
                guard let account = change.account else {
                    throw FinanceStorageError.invalidPendingAccount(
                        id: change.accountId
                    )
                }
                let response = try await dataProvider.updateAccount(
                    id: account.id,
                    request: AccountUpdateRequestDTO(
                        name: account.name,
                        emoji: account.emoji,
                        balance: NSDecimalNumber(
                            decimal: account.balance
                        ).stringValue,
                        currency: account.currency
                    )
                )
                _ = try await localStorage.commitRemoteUpdate(
                    try response.toDomain(),
                    replacingRevision: change.revision
                )
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                guard Self.shouldQuarantine(error) else {
                    throw error
                }
                try await localStorage.markPendingAccountFailed(
                    id: change.accountId,
                    replacingRevision: change.revision,
                    message: Self.errorMessage(from: error)
                )
            }
        }
    }

    private func synchronize(_ change: PendingTransactionChange) async throws {
        switch change.action {
        case .create:
            guard let transaction = change.transaction else {
                throw FinanceStorageError.invalidPendingTransaction(
                    id: change.transactionId
                )
            }
            let response = try await dataProvider.createTransaction(
                TransactionRequestDTO(transaction: transaction)
            )
            let synchronized = try response.toDomain(
                accountsById: [transaction.account.id: transaction.account],
                categoriesById: [transaction.category.id: transaction.category]
            )
            _ = try await localStorage.commitSynchronizedCreation(
                temporaryID: change.transactionId,
                transaction: synchronized,
                replacingRevision: change.revision
            )

        case .update:
            guard let transaction = change.transaction else {
                throw FinanceStorageError.invalidPendingTransaction(
                    id: change.transactionId
                )
            }
            let response = try await dataProvider.updateTransaction(
                id: change.transactionId,
                request: TransactionRequestDTO(transaction: transaction)
            )
            _ = try await localStorage.commitSynchronizedUpdate(
                try response.toDomain(account: transaction.account),
                replacingRevision: change.revision
            )

        case .delete:
            do {
                try await dataProvider.deleteTransaction(id: change.transactionId)
            } catch where Self.isNotFound(error) {
                // The desired server state has already been reached.
            }
            _ = try await localStorage.commitSynchronizedDeletion(
                id: change.transactionId,
                replacingRevision: change.revision
            )
        case .invalid:
            throw FinanceStorageError.invalidPendingTransaction(
                id: change.transactionId
            )
        }
    }

    private func reportIssues(
        transactionChanges: [PendingTransactionChange],
        accountChanges: [PendingAccountChange]
    ) async {
        let transactionIssues: [SynchronizationIssue] = transactionChanges
            .compactMap { change -> SynchronizationIssue? in
                guard change.state == .failed else { return nil }
                return SynchronizationIssue(
                    id: "transaction-\(change.transactionId)",
                    message: change.errorMessage
                        ?? AppLocalization.string(
                            localized: "Не удалось синхронизировать операцию"
                        )
                )
            }
        let accountIssues: [SynchronizationIssue] = accountChanges
            .compactMap { change -> SynchronizationIssue? in
                guard change.state == .failed else { return nil }
                return SynchronizationIssue(
                    id: "account-\(change.accountId)",
                    message: change.errorMessage
                        ?? AppLocalization.string(
                            localized: "Не удалось синхронизировать счёт"
                        )
                )
            }
        await statusReporter.update(issues: transactionIssues + accountIssues)
    }

    private static func shouldQuarantine(
        _ change: PendingTransactionChange,
        after error: Error
    ) -> Bool {
        if error is FinanceStorageError { return true }
        guard let networkError = error as? NetworkError else { return true }
        if networkError.isPermanentClientError { return true }
        return change.action == .create
            && !networkError.allowsSafeCreationDeferral
    }

    private static func shouldQuarantine(_ error: Error) -> Bool {
        guard let networkError = error as? NetworkError else { return true }
        return networkError.isPermanentClientError
    }

    private static func isNotFound(_ error: Error) -> Bool {
        (error as? NetworkError)?.isNotFound == true
    }

    private static func errorMessage(from error: Error) -> String {
        (error as? LocalizedError)?.errorDescription
            ?? error.localizedDescription
    }
}
