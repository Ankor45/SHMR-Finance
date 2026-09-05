//
//  AccountsStorage.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

nonisolated protocol AccountsStorage: Sendable {
    func getAll() async throws -> [BankAccount]
    func get(id: Int) async throws -> BankAccount?
    func save(_ account: BankAccount) async throws
    func replaceAll(with accounts: [BankAccount]) async throws
}

nonisolated struct PendingAccountChange: Equatable, Sendable {
    let accountId: Int
    let account: BankAccount?
    let revision: UUID
    let state: PendingChangeState
    let errorMessage: String?
}

nonisolated protocol AccountsLocalStorage: AccountsStorage {
    func loadPendingAccountChanges() async throws -> [PendingAccountChange]
    func recordLocalUpdate(_ account: BankAccount) async throws

    @discardableResult
    func commitRemoteUpdate(
        _ account: BankAccount,
        replacingRevision revision: UUID?
    ) async throws -> Bool

    func markPendingAccountFailed(
        id: Int,
        replacingRevision revision: UUID,
        message: String
    ) async throws
}

nonisolated protocol FinanceLocalStorage:
    TransactionsLocalStorage,
    AccountsLocalStorage,
    CategoriesStorage {
    func repairPendingChanges() async throws
    func exportSnapshot() async throws -> FinanceStorageSnapshot
    func replaceContents(with snapshot: FinanceStorageSnapshot) async throws
    func removeAll() async throws
}
