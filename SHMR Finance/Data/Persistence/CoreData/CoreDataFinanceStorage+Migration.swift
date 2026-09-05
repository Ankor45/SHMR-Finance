//
//  CoreDataFinanceStorage+Migration.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

@preconcurrency import CoreData
import Foundation

extension CoreDataFinanceStorage {
    func repairPendingChanges() async throws {
        try await perform { try $0.repairPendingChanges() }
    }

    func exportSnapshot() async throws -> FinanceStorageSnapshot {
        try await perform { try $0.exportSnapshot() }
    }

    func replaceContents(with snapshot: FinanceStorageSnapshot) async throws {
        try await perform { try $0.replaceContents(with: snapshot) }
    }

    func removeAll() async throws {
        try await perform { try $0.removeAll() }
    }
}

nonisolated extension CoreDataStorageSession {
    func repairPendingChanges() throws {
        try repairStoredTransactionAccountIds()

        let transactionChanges = try fetch(
            CoreDataPendingTransaction.self,
            entityName: CoreDataPendingTransaction.entityName
        )
        for change in transactionChanges {
            do {
                _ = try decodePendingTransaction(change)
            } catch {
                guard change.stateRawValue != PendingChangeState.failed.rawValue else {
                    continue
                }
                change.stateRawValue = PendingChangeState.failed.rawValue
                change.failureMessage = error.localizedDescription
            }
        }

        let accountChanges = try fetch(
            CoreDataPendingAccount.self,
            entityName: CoreDataPendingAccount.entityName
        )
        for change in accountChanges {
            do {
                _ = try decodePendingAccount(change)
            } catch {
                guard change.stateRawValue != PendingChangeState.failed.rawValue else {
                    continue
                }
                change.stateRawValue = PendingChangeState.failed.rawValue
                change.failureMessage = error.localizedDescription
            }
        }
    }

    private func repairStoredTransactionAccountIds() throws {
        let transactions = try fetch(
            CoreDataStoredTransaction.self,
            entityName: CoreDataStoredTransaction.entityName,
            predicate: NSPredicate(format: "accountId == 0")
        )
        for object in transactions {
            guard let transaction = try? transaction(from: object) else {
                continue
            }
            object.accountId = Int64(transaction.account.id)
        }
    }

    func exportSnapshot() throws -> FinanceStorageSnapshot {
        FinanceStorageSnapshot(
            transactions: try allTransactions(),
            accounts: try allAccounts(),
            categories: try allCategories(),
            pendingTransactions: try fetch(
                CoreDataPendingTransaction.self,
                entityName: CoreDataPendingTransaction.entityName
            ).map {
                PendingTransactionStorageSnapshot(
                    transactionId: Int($0.transactionId),
                    actionRawValue: $0.actionRawValue,
                    payload: $0.payload,
                    balanceAdjustmentPayload: $0.balanceAdjustmentPayload,
                    insertedAt: $0.insertedAt,
                    revision: $0.revision,
                    stateRawValue: $0.stateRawValue,
                    failureMessage: $0.failureMessage
                )
            },
            pendingAccounts: try fetch(
                CoreDataPendingAccount.self,
                entityName: CoreDataPendingAccount.entityName
            ).map {
                PendingAccountStorageSnapshot(
                    accountId: Int($0.accountId),
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
        try removeAll()
        for transaction in snapshot.transactions {
            try upsertTransaction(transaction)
        }
        for account in snapshot.accounts {
            try upsertAccount(account)
        }
        for category in snapshot.categories {
            try upsertCategory(category)
        }
        for change in snapshot.pendingTransactions {
            let object = CoreDataPendingTransaction(
                entity: try entity(named: CoreDataPendingTransaction.entityName),
                insertInto: context
            )
            object.transactionId = Int64(change.transactionId)
            object.actionRawValue = change.actionRawValue
            object.payload = change.payload
            object.balanceAdjustmentPayload = change.balanceAdjustmentPayload
            object.insertedAt = change.insertedAt
            object.revision = change.revision
            object.stateRawValue = change.stateRawValue
            object.failureMessage = change.failureMessage
        }
        for change in snapshot.pendingAccounts {
            let object = CoreDataPendingAccount(
                entity: try entity(named: CoreDataPendingAccount.entityName),
                insertInto: context
            )
            object.accountId = Int64(change.accountId)
            object.payload = change.payload
            object.insertedAt = change.insertedAt
            object.revision = change.revision
            object.stateRawValue = change.stateRawValue
            object.failureMessage = change.failureMessage
        }
    }

    func removeAll() throws {
        try deleteAll(
            CoreDataStoredTransaction.self,
            entityName: CoreDataStoredTransaction.entityName
        )
        try deleteAll(
            CoreDataStoredAccount.self,
            entityName: CoreDataStoredAccount.entityName
        )
        try deleteAll(
            CoreDataStoredCategory.self,
            entityName: CoreDataStoredCategory.entityName
        )
        try deleteAll(
            CoreDataPendingTransaction.self,
            entityName: CoreDataPendingTransaction.entityName
        )
        try deleteAll(
            CoreDataPendingAccount.self,
            entityName: CoreDataPendingAccount.entityName
        )
    }
}
