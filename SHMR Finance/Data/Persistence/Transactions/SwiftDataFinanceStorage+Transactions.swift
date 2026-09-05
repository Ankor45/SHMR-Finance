//
//  SwiftDataFinanceStorage+Transactions.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation
import SwiftData

extension SwiftDataFinanceStorage {
    // MARK: - TransactionsStorage

    func get(
        accountId: Int,
        from: Date,
        to: Date
    ) throws -> [Transaction] {
        let requestedAccountId = accountId
        let startDate = from
        let endDate = to
        let descriptor = FetchDescriptor<StoredTransaction>(
            predicate: #Predicate { transaction in
                transaction.accountId == requestedAccountId
                    && transaction.transactionDate >= startDate
                    && transaction.transactionDate <= endDate
            },
            sortBy: [SortDescriptor(\.transactionDate)]
        )
        return try modelContext.fetch(descriptor).map { try $0.toDomain() }
    }

    // MARK: - Pending Changes

    func loadPendingTransactionChanges() throws
        -> [PendingTransactionChange] {
        let descriptor = FetchDescriptor<StoredPendingTransactionChange>(
            sortBy: [SortDescriptor(\.insertedAt)]
        )
        return try modelContext.fetch(descriptor).map {
            try decodePendingTransactionChange($0)
        }
    }

    func createLocalTransaction(
        account: BankAccount,
        category: Category,
        amount: Decimal,
        transactionDate: Date,
        comment: String?,
        timestamp: Date
    ) throws -> Transaction {
        let temporaryID = try nextTemporaryTransactionID()
        let transaction = Transaction(
            id: temporaryID,
            account: account,
            category: category,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: timestamp,
            updatedAt: timestamp
        )
        let adjustment = TransactionBalanceAdjustment.calculate(
            removing: nil,
            adding: transaction
        )

        try recordCreationChange(
            transaction,
            balanceAdjustment: adjustment
        )
        try upsertStoredTransaction(transaction)
        try applyBalanceAdjustment(
            adjustment,
            fallbackAccounts: [account.id: account]
        )
        try saveChanges()
        return transaction
    }

    func recordLocalUpdate(
        _ transaction: Transaction,
        balanceAdjustment: [Int: Decimal]
    ) throws {
        let previousTransaction = try findStoredTransaction(
            id: transaction.id
        )?.toDomain()
        var fallbackAccounts: [Int: BankAccount] = [
            transaction.account.id: transaction.account
        ]
        if let previousTransaction {
            fallbackAccounts[previousTransaction.account.id] =
                previousTransaction.account
        }

        try recordUpdateChange(
            transaction,
            balanceAdjustment: balanceAdjustment
        )
        try upsertStoredTransaction(transaction)
        try applyBalanceAdjustment(
            balanceAdjustment,
            fallbackAccounts: fallbackAccounts
        )
        try saveChanges()
    }

    func recordLocalDeletion(
        id: Int,
        balanceAdjustment: [Int: Decimal]
    ) throws {
        let previousTransaction = try findStoredTransaction(id: id)?.toDomain()
        let fallbackAccounts = previousTransaction.map {
            [$0.account.id: $0.account]
        } ?? [:]

        try recordDeletionChange(
            id: id,
            balanceAdjustment: balanceAdjustment
        )
        _ = try deleteStoredTransactionIfPresent(id: id)
        try applyBalanceAdjustment(
            balanceAdjustment,
            fallbackAccounts: fallbackAccounts
        )
        try saveChanges()
    }

    func commitRemoteCreation(
        _ transaction: Transaction,
        balanceAdjustment: [Int: Decimal]
    ) throws {
        try removePendingTransactionIfPresent(id: transaction.id)
        try upsertStoredTransaction(transaction)
        try applyBalanceAdjustment(
            balanceAdjustment,
            fallbackAccounts: [transaction.account.id: transaction.account]
        )
        try saveChanges()
    }

    func commitRemoteUpdate(
        _ transaction: Transaction,
        balanceAdjustment: [Int: Decimal]
    ) throws {
        let previousTransaction = try findStoredTransaction(
            id: transaction.id
        )?.toDomain()
        var fallbackAccounts = [transaction.account.id: transaction.account]
        if let previousTransaction {
            fallbackAccounts[previousTransaction.account.id] =
                previousTransaction.account
        }

        try removePendingTransactionIfPresent(id: transaction.id)
        try upsertStoredTransaction(transaction)
        try applyBalanceAdjustment(
            balanceAdjustment,
            fallbackAccounts: fallbackAccounts
        )
        try saveChanges()
    }

    func commitRemoteDeletion(
        id: Int,
        balanceAdjustment: [Int: Decimal]
    ) throws {
        let previousTransaction = try findStoredTransaction(id: id)?.toDomain()
        let fallbackAccounts = previousTransaction.map {
            [$0.account.id: $0.account]
        } ?? [:]

        try removePendingTransactionIfPresent(id: id)
        _ = try deleteStoredTransactionIfPresent(id: id)
        try applyBalanceAdjustment(
            balanceAdjustment,
            fallbackAccounts: fallbackAccounts
        )
        try saveChanges()
    }

    @discardableResult
    func commitSynchronizedCreation(
        temporaryID: Int,
        transaction: Transaction,
        replacingRevision revision: UUID
    ) throws -> Bool {
        guard let storedChange = try findPendingTransaction(id: temporaryID) else {
            return false
        }

        guard storedChange.revision == revision else {
            try preserveNewerCreation(
                storedChange,
                temporaryID: temporaryID,
                synchronizedTransaction: transaction
            )
            try saveChanges()
            return false
        }

        modelContext.delete(storedChange)
        _ = try deleteStoredTransactionIfPresent(id: temporaryID)
        try upsertStoredTransaction(transaction)
        try saveChanges()
        return true
    }

    @discardableResult
    func commitSynchronizedUpdate(
        _ transaction: Transaction,
        replacingRevision revision: UUID
    ) throws -> Bool {
        guard let storedChange = try findPendingTransaction(
            id: transaction.id
        ), storedChange.revision == revision else {
            return false
        }

        modelContext.delete(storedChange)
        try upsertStoredTransaction(transaction)
        try saveChanges()
        return true
    }

    @discardableResult
    func commitSynchronizedDeletion(
        id: Int,
        replacingRevision revision: UUID
    ) throws -> Bool {
        guard let storedChange = try findPendingTransaction(id: id),
              storedChange.revision == revision else {
            return false
        }

        modelContext.delete(storedChange)
        _ = try deleteStoredTransactionIfPresent(id: id)
        try saveChanges()
        return true
    }

    func replaceRemoteTransactions(
        _ transactions: [Transaction],
        accountId: Int,
        from: Date,
        to: Date
    ) throws {
        let requestedAccountId = accountId
        let startDate = from
        let endDate = to
        let descriptor = FetchDescriptor<StoredTransaction>(
            predicate: #Predicate { transaction in
                transaction.accountId == requestedAccountId
                    && transaction.transactionDate >= startDate
                    && transaction.transactionDate <= endDate
            }
        )
        let storedTransactions = try modelContext.fetch(descriptor)
        let remoteIDs = Set(transactions.map(\.id))
        let pendingIDs = Set(
            try loadPendingTransactionChanges().map(\.transactionId)
        )

        for storedTransaction in storedTransactions where
            storedTransaction.transactionId >= .zero
                && !pendingIDs.contains(storedTransaction.transactionId)
                && !remoteIDs.contains(storedTransaction.transactionId) {
            modelContext.delete(storedTransaction)
        }
        for transaction in transactions where !pendingIDs.contains(transaction.id) {
            try upsertStoredTransaction(transaction)
        }
        try saveChanges()
    }

    func markPendingTransactionFailed(
        id: Int,
        replacingRevision revision: UUID,
        message: String
    ) throws {
        guard let storedChange = try findPendingTransaction(id: id),
              storedChange.revision == revision else {
            return
        }

        storedChange.stateRawValue = PendingChangeState.failed.rawValue
        storedChange.failureMessage = message
        try saveChanges()
    }
}
