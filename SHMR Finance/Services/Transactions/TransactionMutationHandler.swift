//
//  TransactionMutationHandler.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation
import OSLog

actor TransactionMutationHandler {
    private let dataProvider: any TransactionDataProviding
    private let localStorage: any TransactionsLocalStorage
    private let synchronizer: any FinanceSynchronizing
    private let dataSourceStatus: any DataSourceStatusReporting
    private let now: @Sendable () -> Date

    private static let logger = AppLogger.make(
        category: "TransactionMutationHandler"
    )

    init(
        dataProvider: any TransactionDataProviding,
        localStorage: any TransactionsLocalStorage,
        synchronizer: any FinanceSynchronizing,
        dataSourceStatus: any DataSourceStatusReporting,
        now: @escaping @Sendable () -> Date
    ) {
        self.dataProvider = dataProvider
        self.localStorage = localStorage
        self.synchronizer = synchronizer
        self.dataSourceStatus = dataSourceStatus
        self.now = now
    }

    func createTransaction(
        account: BankAccount,
        category: Category,
        amount: Decimal,
        transactionDate: Date,
        comment: String?
    ) async throws -> Transaction {
        do {
            try await synchronizer.synchronize()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            guard Self.allowsReadFallback(for: error) else {
                throw error
            }
            return try await createLocalTransaction(
                account: account,
                category: category,
                amount: amount,
                transactionDate: transactionDate,
                comment: comment
            )
        }

        let request = TransactionRequestDTO(
            account: account,
            category: category,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment
        )

        let transaction: Transaction
        do {
            let created = try await dataProvider.createTransaction(request)
            transaction = try created.toDomain(
                accountsById: [account.id: account],
                categoriesById: [category.id: category]
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            guard Self.allowsSafeCreationDeferral(for: error) else {
                throw error
            }

            return try await createLocalTransaction(
                account: account,
                category: category,
                amount: amount,
                transactionDate: transactionDate,
                comment: comment
            )
        }

        do {
            try await localStorage.commitRemoteCreation(
                transaction,
                balanceAdjustment: TransactionBalanceAdjustment.calculate(
                    removing: nil,
                    adding: transaction
                )
            )
        } catch {
            Self.logStorageError(
                error,
                operation: "commit created transaction"
            )
        }
        return transaction
    }

    func updateTransaction(
        _ previousTransaction: Transaction,
        account: BankAccount,
        category: Category,
        amount: Decimal,
        transactionDate: Date,
        comment: String?
    ) async throws -> Transaction {
        let localTransaction = TransactionLocalOverlay.makeUpdatedTransaction(
            previousTransaction,
            account: account,
            category: category,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            timestamp: now()
        )
        let balanceAdjustment = TransactionBalanceAdjustment.calculate(
            removing: previousTransaction,
            adding: localTransaction
        )

        if previousTransaction.id < .zero {
            try await recordLocalUpdate(
                localTransaction,
                previousTransaction: previousTransaction,
                balanceAdjustment: balanceAdjustment
            )
            return localTransaction
        }

        do {
            try await synchronizer.synchronize()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            guard Self.allowsIdempotentDeferral(for: error) else {
                throw error
            }
            try await recordLocalUpdate(
                localTransaction,
                previousTransaction: previousTransaction,
                balanceAdjustment: balanceAdjustment
            )
            return localTransaction
        }

        let request = TransactionRequestDTO(
            account: account,
            category: category,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment
        )

        let transaction: Transaction
        do {
            let updated = try await dataProvider.updateTransaction(
                id: previousTransaction.id,
                request: request
            )
            transaction = try updated.toDomain(account: account)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            guard Self.allowsIdempotentDeferral(for: error) else {
                throw error
            }

            try await recordLocalUpdate(
                localTransaction,
                previousTransaction: previousTransaction,
                balanceAdjustment: balanceAdjustment
            )
            return localTransaction
        }

        do {
            try await localStorage.commitRemoteUpdate(
                transaction,
                balanceAdjustment: balanceAdjustment
            )
        } catch {
            Self.logStorageError(
                error,
                operation: "commit updated transaction"
            )
        }
        return transaction
    }

    func deleteTransaction(_ transaction: Transaction) async throws {
        let balanceAdjustment = TransactionBalanceAdjustment.calculate(
            removing: transaction,
            adding: nil
        )

        if transaction.id < .zero {
            try await recordLocalDeletion(
                transaction,
                balanceAdjustment: balanceAdjustment
            )
            return
        }

        do {
            try await synchronizer.synchronize()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            guard Self.allowsIdempotentDeferral(for: error) else {
                throw error
            }
            try await recordLocalDeletion(
                transaction,
                balanceAdjustment: balanceAdjustment
            )
            return
        }

        do {
            try await dataProvider.deleteTransaction(id: transaction.id)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if !Self.isNotFound(error) {
                guard Self.allowsIdempotentDeferral(for: error) else {
                    throw error
                }

                try await recordLocalDeletion(
                    transaction,
                    balanceAdjustment: balanceAdjustment
                )
                return
            }
        }

        do {
            try await localStorage.commitRemoteDeletion(
                id: transaction.id,
                balanceAdjustment: balanceAdjustment
            )
        } catch {
            Self.logStorageError(
                error,
                operation: "commit deleted transaction"
            )
        }
    }

    private func createLocalTransaction(
        account: BankAccount,
        category: Category,
        amount: Decimal,
        transactionDate: Date,
        comment: String?
    ) async throws -> Transaction {
        let transaction = try await localStorage.createLocalTransaction(
            account: account,
            category: category,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            timestamp: now()
        )
        await dataSourceStatus.didLoadLocalData(
            for: .transactions(accountId: account.id)
        )
        return transaction
    }

    private func recordLocalUpdate(
        _ transaction: Transaction,
        previousTransaction: Transaction,
        balanceAdjustment: [Int: Decimal]
    ) async throws {
        try await localStorage.recordLocalUpdate(
            transaction,
            balanceAdjustment: balanceAdjustment
        )
        await dataSourceStatus.didLoadLocalData(
            for: .transactions(accountId: previousTransaction.account.id)
        )
        await dataSourceStatus.didLoadLocalData(
            for: .transactions(accountId: transaction.account.id)
        )
    }

    private func recordLocalDeletion(
        _ transaction: Transaction,
        balanceAdjustment: [Int: Decimal]
    ) async throws {
        try await localStorage.recordLocalDeletion(
            id: transaction.id,
            balanceAdjustment: balanceAdjustment
        )
        await dataSourceStatus.didLoadLocalData(
            for: .transactions(accountId: transaction.account.id)
        )
    }

    private static func allowsReadFallback(for error: Error) -> Bool {
        (error as? NetworkError)?.allowsLocalFallback == true
    }

    private static func allowsSafeCreationDeferral(for error: Error) -> Bool {
        (error as? NetworkError)?.allowsSafeCreationDeferral == true
    }

    private static func allowsIdempotentDeferral(for error: Error) -> Bool {
        (error as? NetworkError)?.allowsIdempotentMutationDeferral == true
    }

    private static func isNotFound(_ error: Error) -> Bool {
        (error as? NetworkError)?.isNotFound == true
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
