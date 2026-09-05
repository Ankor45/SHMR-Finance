//
//  CoreDataStorageSession+TransactionOutbox.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

@preconcurrency import CoreData
import Foundation

nonisolated extension CoreDataStorageSession {
    func decodePendingTransaction(
        _ object: CoreDataPendingTransaction
    ) throws -> PendingTransactionChange {
        try PendingTransactionCodec.decodeChange(
            transactionId: Int(object.transactionId),
            actionRawValue: object.actionRawValue,
            payload: object.payload,
            balanceAdjustmentPayload: object.balanceAdjustmentPayload,
            revision: object.revision,
            stateRawValue: object.stateRawValue,
            failureMessage: object.failureMessage
        )
    }

    func recordCreationChange(
        _ transaction: Transaction,
        balanceAdjustment: [Int: Decimal]
    ) throws {
        let object = CoreDataPendingTransaction(
            entity: try entity(named: CoreDataPendingTransaction.entityName),
            insertInto: context
        )
        try configurePendingTransaction(
            object,
            id: transaction.id,
            action: .create,
            payload: try PendingTransactionCodec.encodeTransaction(transaction),
            balanceAdjustment: balanceAdjustment
        )
    }

    func recordUpdateChange(
        _ transaction: Transaction,
        balanceAdjustment: [Int: Decimal]
    ) throws {
        if let object = try pendingTransaction(id: transaction.id) {
            guard object.actionRawValue != PendingTransactionAction.delete.rawValue else {
                return
            }
            if object.actionRawValue != PendingTransactionAction.create.rawValue {
                object.actionRawValue = PendingTransactionAction.update.rawValue
            }
            object.payload = try PendingTransactionCodec.encodeTransaction(
                transaction
            )
            object.balanceAdjustmentPayload = try PendingTransactionCodec
                .mergeBalanceAdjustment(
                from: object.balanceAdjustmentPayload,
                with: balanceAdjustment,
                transactionId: transaction.id
            )
            refreshPendingTransaction(object)
        } else {
            let object = CoreDataPendingTransaction(
                entity: try entity(named: CoreDataPendingTransaction.entityName),
                insertInto: context
            )
            try configurePendingTransaction(
                object,
                id: transaction.id,
                action: .update,
                payload: try PendingTransactionCodec.encodeTransaction(
                    transaction
                ),
                balanceAdjustment: balanceAdjustment
            )
        }
    }

    func recordDeletionChange(
        id: Int,
        balanceAdjustment: [Int: Decimal]
    ) throws {
        if let object = try pendingTransaction(id: id) {
            guard let action = PendingTransactionAction(
                rawValue: object.actionRawValue
            ) else {
                throw FinanceStorageError.invalidPendingTransaction(id: id)
            }
            switch action {
            case .create:
                context.delete(object)
                return
            case .update:
                object.actionRawValue = PendingTransactionAction.delete.rawValue
                object.payload = nil
            case .delete:
                break
            case .invalid:
                throw FinanceStorageError.invalidPendingTransaction(id: id)
            }
            object.balanceAdjustmentPayload = try PendingTransactionCodec
                .mergeBalanceAdjustment(
                from: object.balanceAdjustmentPayload,
                with: balanceAdjustment,
                transactionId: id
            )
            refreshPendingTransaction(object)
        } else {
            let object = CoreDataPendingTransaction(
                entity: try entity(named: CoreDataPendingTransaction.entityName),
                insertInto: context
            )
            try configurePendingTransaction(
                object,
                id: id,
                action: .delete,
                payload: nil,
                balanceAdjustment: balanceAdjustment
            )
        }
    }

    func commitSynchronizedCreation(
        temporaryID: Int,
        transaction: Transaction,
        replacingRevision revision: UUID
    ) throws -> Bool {
        guard let change = try pendingTransaction(id: temporaryID) else {
            return false
        }
        guard change.revision == revision else {
            try preserveNewerCreation(
                change,
                temporaryID: temporaryID,
                synchronizedTransaction: transaction
            )
            return false
        }
        context.delete(change)
        _ = try deleteStoredTransaction(id: temporaryID)
        try upsertTransaction(transaction)
        return true
    }

    func commitSynchronizedUpdate(
        _ transaction: Transaction,
        replacingRevision revision: UUID
    ) throws -> Bool {
        guard let change = try pendingTransaction(id: transaction.id),
              change.revision == revision else {
            return false
        }
        context.delete(change)
        try upsertTransaction(transaction)
        return true
    }

    func commitSynchronizedDeletion(
        id: Int,
        replacingRevision revision: UUID
    ) throws -> Bool {
        guard let change = try pendingTransaction(id: id),
              change.revision == revision else {
            return false
        }
        context.delete(change)
        _ = try deleteStoredTransaction(id: id)
        return true
    }

    private func preserveNewerCreation(
        _ change: CoreDataPendingTransaction,
        temporaryID: Int,
        synchronizedTransaction: Transaction
    ) throws {
        guard let payload = change.payload else {
            throw FinanceStorageError.invalidPendingTransaction(id: temporaryID)
        }
        let temporary = try PendingTransactionCodec.decodeTransaction(
            from: payload,
            transactionId: temporaryID
        )
        let latest = Transaction(
            id: synchronizedTransaction.id,
            account: temporary.account,
            category: temporary.category,
            amount: temporary.amount,
            transactionDate: temporary.transactionDate,
            comment: temporary.comment,
            createdAt: synchronizedTransaction.createdAt,
            updatedAt: temporary.updatedAt
        )
        let remaining = TransactionBalanceAdjustment.calculate(
            removing: synchronizedTransaction,
            adding: latest
        )
        context.delete(change)
        _ = try deleteStoredTransaction(id: temporaryID)
        try upsertTransaction(latest)
        let replacement = CoreDataPendingTransaction(
            entity: try entity(named: CoreDataPendingTransaction.entityName),
            insertInto: context
        )
        try configurePendingTransaction(
            replacement,
            id: latest.id,
            action: .update,
            payload: try PendingTransactionCodec.encodeTransaction(latest),
            balanceAdjustment: remaining
        )
    }

    private func configurePendingTransaction(
        _ object: CoreDataPendingTransaction,
        id: Int,
        action: PendingTransactionAction,
        payload: Data?,
        balanceAdjustment: [Int: Decimal]
    ) throws {
        object.transactionId = Int64(id)
        object.actionRawValue = action.rawValue
        object.payload = payload
        object.balanceAdjustmentPayload = try PendingTransactionCodec
            .encodeBalanceAdjustment(balanceAdjustment)
        refreshPendingTransaction(object)
    }

    private func refreshPendingTransaction(
        _ object: CoreDataPendingTransaction
    ) {
        object.insertedAt = .now
        object.revision = UUID()
        object.stateRawValue = PendingChangeState.pending.rawValue
        object.failureMessage = nil
    }
}
