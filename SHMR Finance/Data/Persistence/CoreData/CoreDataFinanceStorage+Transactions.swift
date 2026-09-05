//
//  CoreDataFinanceStorage+Transactions.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation

extension CoreDataFinanceStorage {
    func get(accountId: Int, from: Date, to: Date) async throws
        -> [Transaction] {
        try await perform {
            try $0.transactions(accountId: accountId, from: from, to: to)
        }
    }

    func loadPendingTransactionChanges() async throws
        -> [PendingTransactionChange] {
        try await perform { try $0.pendingTransactionChanges() }
    }

    func createLocalTransaction(
        account: BankAccount,
        category: Category,
        amount: Decimal,
        transactionDate: Date,
        comment: String?,
        timestamp: Date
    ) async throws -> Transaction {
        try await perform {
            try $0.createLocalTransaction(
                account: account,
                category: category,
                amount: amount,
                transactionDate: transactionDate,
                comment: comment,
                timestamp: timestamp
            )
        }
    }

    func recordLocalUpdate(
        _ transaction: Transaction,
        balanceAdjustment: [Int: Decimal]
    ) async throws {
        try await perform {
            try $0.recordLocalTransactionUpdate(
                transaction,
                balanceAdjustment: balanceAdjustment
            )
        }
    }

    func recordLocalDeletion(
        id: Int,
        balanceAdjustment: [Int: Decimal]
    ) async throws {
        try await perform {
            try $0.recordLocalTransactionDeletion(
                id: id,
                balanceAdjustment: balanceAdjustment
            )
        }
    }

    func commitRemoteCreation(
        _ transaction: Transaction,
        balanceAdjustment: [Int: Decimal]
    ) async throws {
        try await perform {
            try $0.commitRemoteTransaction(
                transaction,
                balanceAdjustment: balanceAdjustment
            )
        }
    }

    func commitRemoteUpdate(
        _ transaction: Transaction,
        balanceAdjustment: [Int: Decimal]
    ) async throws {
        try await perform {
            try $0.commitRemoteTransaction(
                transaction,
                balanceAdjustment: balanceAdjustment
            )
        }
    }

    func commitRemoteDeletion(
        id: Int,
        balanceAdjustment: [Int: Decimal]
    ) async throws {
        try await perform {
            try $0.commitRemoteTransactionDeletion(
                id: id,
                balanceAdjustment: balanceAdjustment
            )
        }
    }

    func commitSynchronizedCreation(
        temporaryID: Int,
        transaction: Transaction,
        replacingRevision revision: UUID
    ) async throws -> Bool {
        try await perform {
            try $0.commitSynchronizedCreation(
                temporaryID: temporaryID,
                transaction: transaction,
                replacingRevision: revision
            )
        }
    }

    func commitSynchronizedUpdate(
        _ transaction: Transaction,
        replacingRevision revision: UUID
    ) async throws -> Bool {
        try await perform {
            try $0.commitSynchronizedUpdate(
                transaction,
                replacingRevision: revision
            )
        }
    }

    func commitSynchronizedDeletion(
        id: Int,
        replacingRevision revision: UUID
    ) async throws -> Bool {
        try await perform {
            try $0.commitSynchronizedDeletion(
                id: id,
                replacingRevision: revision
            )
        }
    }

    func replaceRemoteTransactions(
        _ transactions: [Transaction],
        accountId: Int,
        from: Date,
        to: Date
    ) async throws {
        try await perform {
            try $0.replaceRemoteTransactions(
                transactions,
                accountId: accountId,
                from: from,
                to: to
            )
        }
    }

    func markPendingTransactionFailed(
        id: Int,
        replacingRevision revision: UUID,
        message: String
    ) async throws {
        try await perform {
            try $0.markPendingTransactionFailed(
                id: id,
                replacingRevision: revision,
                message: message
            )
        }
    }
}
