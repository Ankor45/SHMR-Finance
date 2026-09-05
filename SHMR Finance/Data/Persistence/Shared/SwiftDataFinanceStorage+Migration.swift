//
//  SwiftDataFinanceStorage+Migration.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation
import SwiftData

extension SwiftDataFinanceStorage {
    func exportSnapshot() throws -> FinanceStorageSnapshot {
        FinanceStorageSnapshot(
            transactions: try modelContext.fetch(
                FetchDescriptor<StoredTransaction>()
            ).map { try $0.toDomain() },
            accounts: try modelContext.fetch(
                FetchDescriptor<StoredBankAccount>()
            ).map { try $0.toDomain() },
            categories: try modelContext.fetch(
                FetchDescriptor<StoredCategory>()
            ).map { try $0.toDomain() },
            pendingTransactions: try modelContext.fetch(
                FetchDescriptor<StoredPendingTransactionChange>()
            ).map {
                PendingTransactionStorageSnapshot(
                    transactionId: $0.transactionId,
                    actionRawValue: $0.actionRawValue,
                    payload: $0.payload,
                    balanceAdjustmentPayload: $0.balanceAdjustmentPayload,
                    insertedAt: $0.insertedAt,
                    revision: $0.revision,
                    stateRawValue: $0.stateRawValue,
                    failureMessage: $0.failureMessage
                )
            },
            pendingAccounts: try modelContext.fetch(
                FetchDescriptor<StoredPendingAccountChange>()
            ).map {
                PendingAccountStorageSnapshot(
                    accountId: $0.accountId,
                    payload: $0.payload,
                    insertedAt: $0.insertedAt,
                    revision: $0.revision,
                    stateRawValue: $0.stateRawValue,
                    failureMessage: $0.failureMessage
                )
            }
        )
    }

    func replaceContents(with snapshot: FinanceStorageSnapshot) throws {
        do {
            try removeAllModels()

            for transaction in snapshot.transactions {
                modelContext.insert(StoredTransaction(transaction: transaction))
            }
            for account in snapshot.accounts {
                modelContext.insert(StoredBankAccount(account: account))
            }
            for category in snapshot.categories {
                modelContext.insert(StoredCategory(category: category))
            }
            for change in snapshot.pendingTransactions {
                modelContext.insert(
                    StoredPendingTransactionChange(snapshot: change)
                )
            }
            for change in snapshot.pendingAccounts {
                modelContext.insert(
                    StoredPendingAccountChange(snapshot: change)
                )
            }

            try saveChanges()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func removeAll() throws {
        do {
            try removeAllModels()
            try saveChanges()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func removeAllModels() throws {
        try modelContext.delete(model: StoredTransaction.self)
        try modelContext.delete(model: StoredBankAccount.self)
        try modelContext.delete(model: StoredCategory.self)
        try modelContext.delete(model: StoredPendingTransactionChange.self)
        try modelContext.delete(model: StoredPendingAccountChange.self)
    }
}
