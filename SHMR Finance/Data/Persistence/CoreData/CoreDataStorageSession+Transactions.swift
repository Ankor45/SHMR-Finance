//
//  CoreDataStorageSession+Transactions.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

@preconcurrency import CoreData
import Foundation

nonisolated extension CoreDataStorageSession {
    func allTransactions() throws -> [Transaction] {
        try fetch(
            CoreDataStoredTransaction.self,
            entityName: CoreDataStoredTransaction.entityName,
            sortDescriptors: [NSSortDescriptor(key: "transactionDate", ascending: true)]
        ).map(transaction(from:))
    }

    func transactions(accountId: Int, from: Date, to: Date) throws
        -> [Transaction] {
        try fetch(
            CoreDataStoredTransaction.self,
            entityName: CoreDataStoredTransaction.entityName,
            predicate: NSPredicate(
                format: "(accountId == %lld OR accountId == 0) "
                    + "AND transactionDate >= %@ AND transactionDate <= %@",
                accountId,
                from as NSDate,
                to as NSDate
            ),
            sortDescriptors: [NSSortDescriptor(key: "transactionDate", ascending: true)]
        ).map(transaction(from:)).filter { $0.account.id == accountId }
    }

    func storedTransaction(id: Int) throws -> CoreDataStoredTransaction? {
        try fetch(
            CoreDataStoredTransaction.self,
            entityName: CoreDataStoredTransaction.entityName,
            predicate: NSPredicate(format: "transactionId == %lld", id)
        ).first
    }

    func pendingTransaction(id: Int) throws -> CoreDataPendingTransaction? {
        try fetch(
            CoreDataPendingTransaction.self,
            entityName: CoreDataPendingTransaction.entityName,
            predicate: NSPredicate(format: "transactionId == %lld", id)
        ).first
    }

    func upsertTransaction(_ transaction: Transaction) throws {
        let object = try storedTransaction(id: transaction.id)
            ?? CoreDataStoredTransaction(
                entity: try entity(named: CoreDataStoredTransaction.entityName),
                insertInto: context
        )
        object.transactionId = Int64(transaction.id)
        object.accountId = Int64(transaction.account.id)
        object.payload = try transactionPayload(transaction)
        object.transactionDate = transaction.transactionDate
    }

    @discardableResult
    func deleteStoredTransaction(id: Int) throws -> Bool {
        guard let object = try storedTransaction(id: id) else {
            return false
        }
        context.delete(object)
        return true
    }

    func removePendingTransaction(id: Int) throws {
        if let object = try pendingTransaction(id: id) {
            context.delete(object)
        }
    }

    func pendingTransactionChanges() throws -> [PendingTransactionChange] {
        try fetch(
            CoreDataPendingTransaction.self,
            entityName: CoreDataPendingTransaction.entityName,
            sortDescriptors: [NSSortDescriptor(key: "insertedAt", ascending: true)]
        ).map(decodePendingTransaction(_:))
    }

    func pendingTransactionBalanceAdjustments() throws -> [Int: Decimal] {
        var result: [Int: Decimal] = [:]
        for change in try pendingTransactionChanges() {
            for (accountID, amount) in change.balanceAdjustment {
                result[accountID, default: .zero] += amount
            }
        }
        return result
    }

    func createLocalTransaction(
        account: BankAccount,
        category: Category,
        amount: Decimal,
        transactionDate: Date,
        comment: String?,
        timestamp: Date
    ) throws -> Transaction {
        let minimumTransactionID = try allTransactions().map(\.id).min() ?? .zero
        let minimumPendingID = try pendingTransactionChanges()
            .map(\.transactionId).min() ?? .zero
        let transaction = Transaction(
            id: min(-1, min(minimumTransactionID, minimumPendingID) - 1),
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
        try recordCreationChange(transaction, balanceAdjustment: adjustment)
        try upsertTransaction(transaction)
        try applyBalanceAdjustment(
            adjustment,
            fallbackAccounts: [account.id: account]
        )
        return transaction
    }

    func recordLocalTransactionUpdate(
        _ transaction: Transaction,
        balanceAdjustment: [Int: Decimal]
    ) throws {
        let previous = try storedTransaction(id: transaction.id)
            .map(transaction(from:))
        var fallback = [transaction.account.id: transaction.account]
        if let previous {
            fallback[previous.account.id] = previous.account
        }
        try recordUpdateChange(transaction, balanceAdjustment: balanceAdjustment)
        try upsertTransaction(transaction)
        try applyBalanceAdjustment(balanceAdjustment, fallbackAccounts: fallback)
    }

    func recordLocalTransactionDeletion(
        id: Int,
        balanceAdjustment: [Int: Decimal]
    ) throws {
        let previous = try storedTransaction(id: id).map(transaction(from:))
        let fallback = previous.map { [$0.account.id: $0.account] } ?? [:]
        try recordDeletionChange(id: id, balanceAdjustment: balanceAdjustment)
        _ = try deleteStoredTransaction(id: id)
        try applyBalanceAdjustment(balanceAdjustment, fallbackAccounts: fallback)
    }

    func commitRemoteTransaction(
        _ transaction: Transaction,
        balanceAdjustment: [Int: Decimal]
    ) throws {
        let previous = try storedTransaction(id: transaction.id)
            .map(transaction(from:))
        var fallback = [transaction.account.id: transaction.account]
        if let previous {
            fallback[previous.account.id] = previous.account
        }
        try removePendingTransaction(id: transaction.id)
        try upsertTransaction(transaction)
        try applyBalanceAdjustment(balanceAdjustment, fallbackAccounts: fallback)
    }

    func commitRemoteTransactionDeletion(
        id: Int,
        balanceAdjustment: [Int: Decimal]
    ) throws {
        let previous = try storedTransaction(id: id).map(transaction(from:))
        let fallback = previous.map { [$0.account.id: $0.account] } ?? [:]
        try removePendingTransaction(id: id)
        _ = try deleteStoredTransaction(id: id)
        try applyBalanceAdjustment(balanceAdjustment, fallbackAccounts: fallback)
    }

    func replaceRemoteTransactions(
        _ transactions: [Transaction],
        accountId: Int,
        from: Date,
        to: Date
    ) throws {
        let stored = try self.transactions(accountId: accountId, from: from, to: to)
        let remoteIDs = Set(transactions.map(\.id))
        let pendingIDs = Set(try pendingTransactionChanges().map(\.transactionId))
        for transaction in stored where transaction.id >= .zero
            && !pendingIDs.contains(transaction.id)
            && !remoteIDs.contains(transaction.id) {
            _ = try deleteStoredTransaction(id: transaction.id)
        }
        for transaction in transactions where !pendingIDs.contains(transaction.id) {
            try upsertTransaction(transaction)
        }
    }

    func markPendingTransactionFailed(
        id: Int,
        replacingRevision revision: UUID,
        message: String
    ) throws {
        guard let change = try pendingTransaction(id: id),
              change.revision == revision else {
            return
        }
        change.stateRawValue = PendingChangeState.failed.rawValue
        change.failureMessage = message
    }
}
