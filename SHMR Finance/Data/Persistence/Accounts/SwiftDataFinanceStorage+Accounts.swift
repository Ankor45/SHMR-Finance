//
//  SwiftDataFinanceStorage+Accounts.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation
import SwiftData

extension SwiftDataFinanceStorage {
    // MARK: - AccountsStorage

    func getAll() throws -> [BankAccount] {
        let descriptor = FetchDescriptor<StoredBankAccount>(
            sortBy: [SortDescriptor(\.accountId)]
        )
        return try modelContext.fetch(descriptor).map { try $0.toDomain() }
    }

    func get(id: Int) throws -> BankAccount? {
        try findStoredAccount(id: id)?.toDomain()
    }

    func save(_ account: BankAccount) throws {
        let mergedAccount = try mergeRemoteAccountWithPendingState(account)
        try upsertStoredAccount(mergedAccount)
        try saveChanges()
    }

    func replaceAll(with accounts: [BankAccount]) throws {
        var pendingAccounts: [Int: BankAccount] = [:]
        for change in try loadPendingAccountChanges() {
            if let account = change.account {
                pendingAccounts[change.accountId] = account
            }
        }
        let transactionAdjustments = try pendingTransactionBalanceAdjustments()
        let remoteIDs = Set(accounts.map(\.id))
        let protectedIDs = Set(pendingAccounts.keys)
            .union(transactionAdjustments.keys)

        let storedAccounts = try modelContext.fetch(
            FetchDescriptor<StoredBankAccount>()
        )
        for storedAccount in storedAccounts where
            !remoteIDs.contains(storedAccount.accountId)
                && !protectedIDs.contains(storedAccount.accountId) {
            modelContext.delete(storedAccount)
        }

        for remoteAccount in accounts {
            let account: BankAccount
            if let pendingAccount = pendingAccounts[remoteAccount.id] {
                account = pendingAccount
            } else {
                var adjustedAccount = remoteAccount
                adjustedAccount.balance += transactionAdjustments[
                    remoteAccount.id,
                    default: .zero
                ]
                account = adjustedAccount
            }
            try upsertStoredAccount(account)
        }

        for pendingAccount in pendingAccounts.values where
            !remoteIDs.contains(pendingAccount.id) {
            try upsertStoredAccount(pendingAccount)
        }

        try saveChanges()
    }

    // MARK: - Pending Changes

    func loadPendingAccountChanges() throws -> [PendingAccountChange] {
        let descriptor = FetchDescriptor<StoredPendingAccountChange>(
            sortBy: [SortDescriptor(\.insertedAt)]
        )
        return try modelContext.fetch(descriptor).map {
            try decodePendingAccountChange($0)
        }
    }

    func recordLocalUpdate(_ account: BankAccount) throws {
        let payload = try PendingAccountCodec.encode(account)

        if let storedChange = try findPendingAccount(id: account.id) {
            storedChange.payload = payload
            refreshPendingAccount(storedChange)
        } else {
            modelContext.insert(
                StoredPendingAccountChange(
                    accountId: account.id,
                    payload: payload
                )
            )
        }
        try upsertStoredAccount(account)
        try saveChanges()
    }

    @discardableResult
    func commitRemoteUpdate(
        _ account: BankAccount,
        replacingRevision revision: UUID?
    ) throws -> Bool {
        let storedChange = try findPendingAccount(id: account.id)

        if let storedChange {
            guard let revision,
                  storedChange.revision == revision else {
                return false
            }
            modelContext.delete(storedChange)
        } else if revision != nil {
            return false
        }

        try upsertStoredAccount(account)
        try saveChanges()
        return true
    }

    func markPendingAccountFailed(
        id: Int,
        replacingRevision revision: UUID,
        message: String
    ) throws {
        guard let storedChange = try findPendingAccount(id: id),
              storedChange.revision == revision else {
            return
        }

        storedChange.stateRawValue = PendingChangeState.failed.rawValue
        storedChange.failureMessage = message
        try saveChanges()
    }

    // MARK: - Shared Account Helpers

    func decodePendingAccountChange(
        _ storedChange: StoredPendingAccountChange
    ) throws -> PendingAccountChange {
        try PendingAccountCodec.decodeChange(
            accountId: storedChange.accountId,
            payload: storedChange.payload,
            revision: storedChange.revision,
            stateRawValue: storedChange.stateRawValue,
            failureMessage: storedChange.failureMessage
        )
    }

    func applyBalanceAdjustment(
        _ adjustment: [Int: Decimal],
        fallbackAccounts: [Int: BankAccount]
    ) throws {
        for (accountID, amount) in adjustment where amount != .zero {
            let cachedAccount = try findStoredAccount(id: accountID)?.toDomain()
            guard var account = cachedAccount ?? fallbackAccounts[accountID] else {
                continue
            }

            account.balance += amount
            try upsertStoredAccount(account)
            try rebasePendingAccount(
                id: accountID,
                toBalance: account.balance
            )
        }
    }

    private func mergeRemoteAccountWithPendingState(
        _ account: BankAccount
    ) throws -> BankAccount {
        if let pendingAccount = try findPendingAccount(id: account.id) {
            return try decodePendingAccountChange(pendingAccount).account
                ?? account
        }

        var result = account
        result.balance += try pendingTransactionBalanceAdjustments()[
            account.id,
            default: .zero
        ]
        return result
    }

    private func rebasePendingAccount(
        id: Int,
        toBalance balance: Decimal
    ) throws {
        guard let storedChange = try findPendingAccount(id: id) else {
            return
        }

        guard var pendingAccount = try decodePendingAccountChange(
            storedChange
        ).account else {
            return
        }
        pendingAccount.balance = balance
        storedChange.payload = try PendingAccountCodec.encode(pendingAccount)
        refreshPendingAccount(storedChange)
    }

    private func refreshPendingAccount(
        _ storedChange: StoredPendingAccountChange
    ) {
        storedChange.revision = UUID()
        storedChange.insertedAt = .now
        storedChange.stateRawValue = PendingChangeState.pending.rawValue
        storedChange.failureMessage = nil
    }

    private func findStoredAccount(id: Int) throws -> StoredBankAccount? {
        let accountId = id
        var descriptor = FetchDescriptor<StoredBankAccount>(
            predicate: #Predicate { account in
                account.accountId == accountId
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func findPendingAccount(
        id: Int
    ) throws -> StoredPendingAccountChange? {
        let accountId = id
        var descriptor = FetchDescriptor<StoredPendingAccountChange>(
            predicate: #Predicate { change in
                change.accountId == accountId
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func upsertStoredAccount(_ account: BankAccount) throws {
        if let storedAccount = try findStoredAccount(id: account.id) {
            storedAccount.update(with: account)
        } else {
            modelContext.insert(StoredBankAccount(account: account))
        }
    }
}
