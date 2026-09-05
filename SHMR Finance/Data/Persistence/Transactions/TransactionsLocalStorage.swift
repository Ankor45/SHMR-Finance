//
//  TransactionsLocalStorage.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

nonisolated enum PendingTransactionAction: String, Equatable, Sendable {
    case create
    case update
    case delete
    case invalid
}

nonisolated enum PendingChangeState: String, Equatable, Sendable {
    case pending
    case failed
}

nonisolated struct PendingTransactionChange: Equatable, Sendable {
    let transactionId: Int
    let action: PendingTransactionAction
    let transaction: Transaction?
    let balanceAdjustment: [Int: Decimal]
    let revision: UUID
    let state: PendingChangeState
    let errorMessage: String?
}

nonisolated protocol TransactionsLocalStorage: TransactionsStorage {
    func loadPendingTransactionChanges() async throws
        -> [PendingTransactionChange]

    func createLocalTransaction(
        account: BankAccount,
        category: Category,
        amount: Decimal,
        transactionDate: Date,
        comment: String?,
        timestamp: Date
    ) async throws -> Transaction

    func recordLocalUpdate(
        _ transaction: Transaction,
        balanceAdjustment: [Int: Decimal]
    ) async throws
    func recordLocalDeletion(
        id: Int,
        balanceAdjustment: [Int: Decimal]
    ) async throws

    func commitRemoteCreation(
        _ transaction: Transaction,
        balanceAdjustment: [Int: Decimal]
    ) async throws
    func commitRemoteUpdate(
        _ transaction: Transaction,
        balanceAdjustment: [Int: Decimal]
    ) async throws
    func commitRemoteDeletion(
        id: Int,
        balanceAdjustment: [Int: Decimal]
    ) async throws

    @discardableResult
    func commitSynchronizedCreation(
        temporaryID: Int,
        transaction: Transaction,
        replacingRevision revision: UUID
    ) async throws -> Bool
    @discardableResult
    func commitSynchronizedUpdate(
        _ transaction: Transaction,
        replacingRevision revision: UUID
    ) async throws -> Bool
    @discardableResult
    func commitSynchronizedDeletion(
        id: Int,
        replacingRevision revision: UUID
    ) async throws -> Bool

    func replaceRemoteTransactions(
        _ transactions: [Transaction],
        accountId: Int,
        from: Date,
        to: Date
    ) async throws

    func markPendingTransactionFailed(
        id: Int,
        replacingRevision revision: UUID,
        message: String
    ) async throws
}
