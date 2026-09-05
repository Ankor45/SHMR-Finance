//
//  CoreDataFinanceStorage+Accounts.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

@preconcurrency import CoreData
import Foundation

extension CoreDataFinanceStorage {
    func getAll() async throws -> [BankAccount] {
        try await perform { try $0.allAccounts() }
    }

    func get(id: Int) async throws -> BankAccount? {
        try await perform { try $0.storedAccount(id: id).map($0.account(from:)) }
    }

    func save(_ account: BankAccount) async throws {
        try await perform { session in
            try session.upsertAccount(
                session.mergeRemoteAccountWithPendingState(account)
            )
        }
    }

    func replaceAll(with accounts: [BankAccount]) async throws {
        try await perform { try $0.replaceAllAccounts(with: accounts) }
    }

    func loadPendingAccountChanges() async throws -> [PendingAccountChange] {
        try await perform { try $0.pendingAccountChanges() }
    }

    func recordLocalUpdate(_ account: BankAccount) async throws {
        try await perform { try $0.recordLocalAccountUpdate(account) }
    }

    func commitRemoteUpdate(
        _ account: BankAccount,
        replacingRevision revision: UUID?
    ) async throws -> Bool {
        try await perform {
            try $0.commitRemoteAccountUpdate(
                account,
                replacingRevision: revision
            )
        }
    }

    func markPendingAccountFailed(
        id: Int,
        replacingRevision revision: UUID,
        message: String
    ) async throws {
        try await perform {
            try $0.markPendingAccountFailed(
                id: id,
                replacingRevision: revision,
                message: message
            )
        }
    }
}

nonisolated extension CoreDataStorageSession {
    func allAccounts() throws -> [BankAccount] {
        try fetch(
            CoreDataStoredAccount.self,
            entityName: CoreDataStoredAccount.entityName,
            sortDescriptors: [NSSortDescriptor(key: "accountId", ascending: true)]
        ).map(account(from:))
    }

    func storedAccount(id: Int) throws -> CoreDataStoredAccount? {
        try fetch(
            CoreDataStoredAccount.self,
            entityName: CoreDataStoredAccount.entityName,
            predicate: NSPredicate(format: "accountId == %lld", id)
        ).first
    }

    func pendingAccount(id: Int) throws -> CoreDataPendingAccount? {
        try fetch(
            CoreDataPendingAccount.self,
            entityName: CoreDataPendingAccount.entityName,
            predicate: NSPredicate(format: "accountId == %lld", id)
        ).first
    }

    func upsertAccount(_ account: BankAccount) throws {
        let object = try storedAccount(id: account.id)
            ?? CoreDataStoredAccount(
                entity: try entity(named: CoreDataStoredAccount.entityName),
                insertInto: context
            )
        object.accountId = Int64(account.id)
        object.payload = try encoder.encode(account)
    }

    func pendingAccountChanges() throws -> [PendingAccountChange] {
        try fetch(
            CoreDataPendingAccount.self,
            entityName: CoreDataPendingAccount.entityName,
            sortDescriptors: [NSSortDescriptor(key: "insertedAt", ascending: true)]
        ).map(decodePendingAccount(_:))
    }

    func decodePendingAccount(
        _ object: CoreDataPendingAccount
    ) throws -> PendingAccountChange {
        try PendingAccountCodec.decodeChange(
            accountId: Int(object.accountId),
            payload: object.payload,
            revision: object.revision,
            stateRawValue: object.stateRawValue,
            failureMessage: object.failureMessage
        )
    }

    func recordLocalAccountUpdate(_ account: BankAccount) throws {
        let object = try pendingAccount(id: account.id)
            ?? CoreDataPendingAccount(
                entity: try entity(named: CoreDataPendingAccount.entityName),
                insertInto: context
            )
        object.accountId = Int64(account.id)
        object.payload = try PendingAccountCodec.encode(account)
        refreshPendingAccount(object)
        try upsertAccount(account)
    }

    func commitRemoteAccountUpdate(
        _ account: BankAccount,
        replacingRevision revision: UUID?
    ) throws -> Bool {
        if let change = try pendingAccount(id: account.id) {
            guard let revision, change.revision == revision else {
                return false
            }
            context.delete(change)
        } else if revision != nil {
            return false
        }
        try upsertAccount(account)
        return true
    }

    func markPendingAccountFailed(
        id: Int,
        replacingRevision revision: UUID,
        message: String
    ) throws {
        guard let change = try pendingAccount(id: id),
              change.revision == revision else {
            return
        }
        change.stateRawValue = PendingChangeState.failed.rawValue
        change.failureMessage = message
    }

    func replaceAllAccounts(with accounts: [BankAccount]) throws {
        let pendingAccounts = Dictionary(
            uniqueKeysWithValues: try pendingAccountChanges().compactMap {
                change in change.account.map { (change.accountId, $0) }
            }
        )
        let transactionAdjustments = try pendingTransactionBalanceAdjustments()
        let remoteIDs = Set(accounts.map(\.id))
        let protectedIDs = Set(pendingAccounts.keys)
            .union(transactionAdjustments.keys)
        let stored = try fetch(
            CoreDataStoredAccount.self,
            entityName: CoreDataStoredAccount.entityName
        )
        for object in stored where
            !remoteIDs.contains(Int(object.accountId))
                && !protectedIDs.contains(Int(object.accountId)) {
            context.delete(object)
        }
        for remoteAccount in accounts {
            var account = pendingAccounts[remoteAccount.id] ?? remoteAccount
            if pendingAccounts[remoteAccount.id] == nil {
                account.balance += transactionAdjustments[
                    remoteAccount.id,
                    default: .zero
                ]
            }
            try upsertAccount(account)
        }
        for account in pendingAccounts.values where
            !remoteIDs.contains(account.id) {
            try upsertAccount(account)
        }
    }

    func applyBalanceAdjustment(
        _ adjustment: [Int: Decimal],
        fallbackAccounts: [Int: BankAccount]
    ) throws {
        for (accountID, amount) in adjustment where amount != .zero {
            let cached = try storedAccount(id: accountID).map(account(from:))
            guard var account = cached ?? fallbackAccounts[accountID] else {
                continue
            }
            account.balance += amount
            try upsertAccount(account)
            try rebasePendingAccount(id: accountID, toBalance: account.balance)
        }
    }

    func mergeRemoteAccountWithPendingState(
        _ account: BankAccount
    ) throws -> BankAccount {
        if let pending = try pendingAccount(id: account.id) {
            return try decodePendingAccount(pending).account ?? account
        }
        var result = account
        result.balance += try pendingTransactionBalanceAdjustments()[
            account.id,
            default: .zero
        ]
        return result
    }

    private func rebasePendingAccount(id: Int, toBalance balance: Decimal) throws {
        guard let object = try pendingAccount(id: id),
              var account = try decodePendingAccount(object).account else {
            return
        }
        account.balance = balance
        object.payload = try PendingAccountCodec.encode(account)
        refreshPendingAccount(object)
    }

    private func refreshPendingAccount(_ object: CoreDataPendingAccount) {
        object.insertedAt = .now
        object.revision = UUID()
        object.stateRawValue = PendingChangeState.pending.rawValue
        object.failureMessage = nil
    }
}
