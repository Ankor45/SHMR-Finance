//
//  SwiftDataFinanceStorage+TransactionOutbox.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation
import SwiftData

extension SwiftDataFinanceStorage {
    // MARK: - Internal Helpers

    func decodePendingTransactionChange(
        _ storedChange: StoredPendingTransactionChange
    ) throws -> PendingTransactionChange {
        try PendingTransactionCodec.decodeChange(
            transactionId: storedChange.transactionId,
            actionRawValue: storedChange.actionRawValue,
            payload: storedChange.payload,
            balanceAdjustmentPayload: storedChange.balanceAdjustmentPayload,
            revision: storedChange.revision,
            stateRawValue: storedChange.stateRawValue,
            failureMessage: storedChange.failureMessage
        )
    }

    func pendingTransactionBalanceAdjustments() throws -> [Int: Decimal] {
        let changes = try loadPendingTransactionChanges()
        var result: [Int: Decimal] = [:]

        for change in changes {
            for (accountID, amount) in change.balanceAdjustment {
                result[accountID, default: .zero] += amount
            }
        }
        return result
    }

    func nextTemporaryTransactionID() throws -> Int {
        var transactionDescriptor = FetchDescriptor<StoredTransaction>(
            sortBy: [SortDescriptor(\.transactionId)]
        )
        transactionDescriptor.fetchLimit = 1
        var pendingDescriptor = FetchDescriptor<StoredPendingTransactionChange>(
            sortBy: [SortDescriptor(\.transactionId)]
        )
        pendingDescriptor.fetchLimit = 1

        let storedMinimum = try modelContext.fetch(
            transactionDescriptor
        ).first?.transactionId ?? .zero
        let pendingMinimum = try modelContext.fetch(
            pendingDescriptor
        ).first?.transactionId ?? .zero
        return min(-1, min(storedMinimum, pendingMinimum) - 1)
    }

    func recordCreationChange(
        _ transaction: Transaction,
        balanceAdjustment: [Int: Decimal]
    ) throws {
        modelContext.insert(
            StoredPendingTransactionChange(
                transactionId: transaction.id,
                action: .create,
                payload: try PendingTransactionCodec.encodeTransaction(transaction),
                balanceAdjustmentPayload: try PendingTransactionCodec.encodeBalanceAdjustment(
                    balanceAdjustment
                )
            )
        )
    }

    func recordUpdateChange(
        _ transaction: Transaction,
        balanceAdjustment: [Int: Decimal]
    ) throws {
        let payload = try PendingTransactionCodec.encodeTransaction(transaction)
        let adjustmentPayload = try PendingTransactionCodec
            .encodeBalanceAdjustment(balanceAdjustment)

        if let storedChange = try findPendingTransaction(id: transaction.id) {
            guard let currentAction = storedChange.action,
                  currentAction != .delete else {
                return
            }

            if currentAction != .create {
                storedChange.actionRawValue = PendingTransactionAction.update.rawValue
            }
            storedChange.payload = payload
            storedChange.balanceAdjustmentPayload = try PendingTransactionCodec
                .mergeBalanceAdjustment(
                from: storedChange.balanceAdjustmentPayload,
                with: balanceAdjustment,
                transactionId: transaction.id
            )
            refreshPendingTransaction(storedChange)
        } else {
            modelContext.insert(
                StoredPendingTransactionChange(
                    transactionId: transaction.id,
                    action: .update,
                    payload: payload,
                    balanceAdjustmentPayload: adjustmentPayload
                )
            )
        }
    }

    func recordDeletionChange(
        id: Int,
        balanceAdjustment: [Int: Decimal]
    ) throws {
        if let storedChange = try findPendingTransaction(id: id) {
            switch storedChange.action {
            case .create:
                modelContext.delete(storedChange)
                return
            case .update:
                storedChange.actionRawValue = PendingTransactionAction.delete.rawValue
                storedChange.payload = nil
            case .delete:
                break
            case .invalid:
                throw FinanceStorageError.invalidPendingTransaction(id: id)
            case nil:
                throw FinanceStorageError.invalidPendingTransaction(id: id)
            }
            storedChange.balanceAdjustmentPayload = try PendingTransactionCodec
                .mergeBalanceAdjustment(
                from: storedChange.balanceAdjustmentPayload,
                with: balanceAdjustment,
                transactionId: id
            )
            refreshPendingTransaction(storedChange)
        } else {
            modelContext.insert(
                StoredPendingTransactionChange(
                    transactionId: id,
                    action: .delete,
                    payload: nil,
                    balanceAdjustmentPayload: try PendingTransactionCodec
                        .encodeBalanceAdjustment(
                        balanceAdjustment
                    )
                )
            )
        }
    }

    func preserveNewerCreation(
        _ storedChange: StoredPendingTransactionChange,
        temporaryID: Int,
        synchronizedTransaction: Transaction
    ) throws {
        guard let payload = storedChange.payload else {
            throw FinanceStorageError.invalidPendingTransaction(id: temporaryID)
        }
        let latestTemporaryTransaction = try PendingTransactionCodec
            .decodeTransaction(
            from: payload,
            transactionId: temporaryID
        )
        let latestTransaction = Transaction(
            id: synchronizedTransaction.id,
            account: latestTemporaryTransaction.account,
            category: latestTemporaryTransaction.category,
            amount: latestTemporaryTransaction.amount,
            transactionDate: latestTemporaryTransaction.transactionDate,
            comment: latestTemporaryTransaction.comment,
            createdAt: synchronizedTransaction.createdAt,
            updatedAt: latestTemporaryTransaction.updatedAt
        )
        let remainingAdjustment = TransactionBalanceAdjustment.calculate(
            removing: synchronizedTransaction,
            adding: latestTransaction
        )

        modelContext.delete(storedChange)
        _ = try deleteStoredTransactionIfPresent(id: temporaryID)
        try upsertStoredTransaction(latestTransaction)
        modelContext.insert(
            StoredPendingTransactionChange(
                transactionId: latestTransaction.id,
                action: .update,
                payload: try PendingTransactionCodec.encodeTransaction(
                    latestTransaction
                ),
                balanceAdjustmentPayload: try PendingTransactionCodec
                    .encodeBalanceAdjustment(
                    remainingAdjustment
                ),
                insertedAt: .now
            )
        )
    }

    func refreshPendingTransaction(
        _ storedChange: StoredPendingTransactionChange
    ) {
        storedChange.revision = UUID()
        storedChange.insertedAt = .now
        storedChange.stateRawValue = PendingChangeState.pending.rawValue
        storedChange.failureMessage = nil
    }

    func findStoredTransaction(id: Int) throws -> StoredTransaction? {
        let transactionId = id
        var descriptor = FetchDescriptor<StoredTransaction>(
            predicate: #Predicate { transaction in
                transaction.transactionId == transactionId
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func findPendingTransaction(
        id: Int
    ) throws -> StoredPendingTransactionChange? {
        let transactionId = id
        var descriptor = FetchDescriptor<StoredPendingTransactionChange>(
            predicate: #Predicate { change in
                change.transactionId == transactionId
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func upsertStoredTransaction(_ transaction: Transaction) throws {
        if let storedTransaction = try findStoredTransaction(id: transaction.id) {
            storedTransaction.update(with: transaction)
        } else {
            modelContext.insert(StoredTransaction(transaction: transaction))
        }
    }

    @discardableResult
    func deleteStoredTransactionIfPresent(id: Int) throws -> Bool {
        guard let storedTransaction = try findStoredTransaction(id: id) else {
            return false
        }
        modelContext.delete(storedTransaction)
        return true
    }

    func removePendingTransactionIfPresent(id: Int) throws {
        guard let storedChange = try findPendingTransaction(id: id) else {
            return
        }
        modelContext.delete(storedChange)
    }
}
