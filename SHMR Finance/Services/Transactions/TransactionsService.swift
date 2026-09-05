//
//  TransactionsService.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation
import OSLog

nonisolated final class TransactionsService:
    TransactionServiceProviding,
    Sendable {
    private let dataProvider: any TransactionDataProviding
    private let localStorage: any TransactionsLocalStorage
    private let synchronizer: any FinanceSynchronizing
    private let mutationHandler: TransactionMutationHandler
    private let dataSourceStatus: any DataSourceStatusReporting

    private static let logger = AppLogger.make(category: "TransactionsService")

    init(
        dataProvider: any TransactionDataProviding,
        localStorage: any TransactionsLocalStorage,
        synchronizer: any FinanceSynchronizing,
        dataSourceStatus: any DataSourceStatusReporting,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.dataProvider = dataProvider
        self.localStorage = localStorage
        self.synchronizer = synchronizer
        self.dataSourceStatus = dataSourceStatus
        mutationHandler = TransactionMutationHandler(
            dataProvider: dataProvider,
            localStorage: localStorage,
            synchronizer: synchronizer,
            dataSourceStatus: dataSourceStatus,
            now: now
        )
    }

    // MARK: - Transactions

    func getTransactions(
        account: BankAccount,
        from: Date,
        to: Date
    ) async throws -> [Transaction] {
        do {
            try await synchronizer.synchronize()

            let responses = try await dataProvider.fetchTransactions(
                accountId: account.id,
                from: from,
                to: to
            )
            let remoteTransactions = try responses.map {
                try $0.toDomain(account: account)
            }
            let requestedTransactions = remoteTransactions.filter {
                $0.transactionDate >= from
                    && $0.transactionDate <= to
            }

            do {
                try await localStorage.replaceRemoteTransactions(
                    requestedTransactions,
                    accountId: account.id,
                    from: from,
                    to: to
                )
            } catch {
                Self.logStorageError(
                    error,
                    operation: "replace transactions"
                )
            }

            do {
                let transactions = try await overlayPendingChanges(
                    on: requestedTransactions,
                    accountId: account.id,
                    from: from,
                    to: to
                )
                await dataSourceStatus.didLoadRemoteData(
                    for: .transactions(accountId: account.id)
                )
                return transactions
            } catch {
                Self.logStorageError(
                    error,
                    operation: "overlay pending transactions"
                )
                await dataSourceStatus.didLoadRemoteData(
                    for: .transactions(accountId: account.id)
                )
                return requestedTransactions
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            guard Self.allowsReadFallback(for: error) else {
                throw error
            }

            let cachedTransactions = try await localStorage.get(
                accountId: account.id,
                from: from,
                to: to
            )
            let transactions = try await overlayPendingChanges(
                on: cachedTransactions,
                accountId: account.id,
                from: from,
                to: to
            )
            await dataSourceStatus.didLoadLocalData(
                for: .transactions(accountId: account.id)
            )
            return transactions
        }
    }

    func createTransaction(
        account: BankAccount,
        category: Category,
        amount: Decimal,
        transactionDate: Date,
        comment: String?
    ) async throws -> Transaction {
        try await mutationHandler.createTransaction(
            account: account,
            category: category,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment
        )
    }

    func updateTransaction(
        _ transaction: Transaction,
        account: BankAccount,
        category: Category,
        amount: Decimal,
        transactionDate: Date,
        comment: String?
    ) async throws -> Transaction {
        try await mutationHandler.updateTransaction(
            transaction,
            account: account,
            category: category,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment
        )
    }

    func deleteTransaction(_ transaction: Transaction) async throws {
        try await mutationHandler.deleteTransaction(transaction)
    }

    // MARK: - Local Data

    private func overlayPendingChanges(
        on transactions: [Transaction],
        accountId: Int,
        from: Date,
        to: Date
    ) async throws -> [Transaction] {
        let pendingChanges = try await localStorage
            .loadPendingTransactionChanges()
        return TransactionLocalOverlay.overlay(
            pendingChanges,
            on: transactions,
            accountId: accountId,
            from: from,
            to: to
        )
    }

    // MARK: - Helpers

    private static func allowsReadFallback(for error: Error) -> Bool {
        (error as? NetworkError)?.allowsLocalFallback == true
    }

    private static func logStorageError(
        _ error: Error,
        operation: String
    ) {
        logger.error(
            "Local storage failed during \(operation, privacy: .public): \(error.localizedDescription, privacy: .public)"
        )
    }
}
