//
//  BankAccountsService.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation
import OSLog

actor BankAccountsService: AccountServiceProviding {
    private let dataProvider: any AccountDataProviding
    private let localStorage: any FinanceLocalStorage
    private let synchronizer: any FinanceSynchronizing
    private let dataSourceStatus: any DataSourceStatusReporting

    private static let logger = AppLogger.make(category: "BankAccountsService")

    init(
        dataProvider: any AccountDataProviding,
        localStorage: any FinanceLocalStorage,
        synchronizer: any FinanceSynchronizing,
        dataSourceStatus: any DataSourceStatusReporting
    ) {
        self.dataProvider = dataProvider
        self.localStorage = localStorage
        self.synchronizer = synchronizer
        self.dataSourceStatus = dataSourceStatus
    }

    func getAccounts() async throws -> [BankAccount] {
        do {
            try await synchronizer.synchronize()
            let accounts = try await dataProvider.fetchAccounts().map {
                try $0.toDomain()
            }
            do {
                try await localStorage.replaceAll(with: accounts)
                let mergedAccounts: [BankAccount] = try await localStorage.getAll()
                await dataSourceStatus.didLoadRemoteData(for: .accounts)
                return mergedAccounts
            } catch {
                Self.logCacheError(error, operation: "replace accounts")
                await dataSourceStatus.didLoadRemoteData(for: .accounts)
                return accounts
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            guard Self.allowsReadFallback(for: error) else { throw error }
            let cachedAccounts: [BankAccount] = try await localStorage.getAll()
            await dataSourceStatus.didLoadLocalData(for: .accounts)
            return cachedAccounts
        }
    }

    func updateAccount(_ account: BankAccount) async throws -> BankAccount {
        do {
            try await synchronizer.synchronize()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            guard Self.allowsIdempotentDeferral(for: error) else { throw error }
            return try await saveLocally(account)
        }

        let hasFailedTransaction = try await localStorage
            .loadPendingTransactionChanges()
            .contains { $0.state == .failed }
        if hasFailedTransaction {
            return try await saveLocally(account)
        }

        let replacedRevision = try await localStorage
            .loadPendingAccountChanges()
            .last(where: { $0.accountId == account.id })?
            .revision

        do {
            let response = try await dataProvider.updateAccount(
                id: account.id,
                request: Self.makeRequest(from: account)
            )
            let updatedAccount = try response.toDomain()
            _ = try await localStorage.commitRemoteUpdate(
                updatedAccount,
                replacingRevision: replacedRevision
            )
            return try await localStorage.get(id: account.id) ?? updatedAccount
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            guard Self.allowsIdempotentDeferral(for: error) else { throw error }
            return try await saveLocally(account)
        }
    }

    private func saveLocally(_ account: BankAccount) async throws -> BankAccount {
        try await localStorage.recordLocalUpdate(account)
        await dataSourceStatus.didLoadLocalData(for: .accounts)
        return account
    }

    private static func makeRequest(
        from account: BankAccount
    ) -> AccountUpdateRequestDTO {
        AccountUpdateRequestDTO(
            name: account.name,
            emoji: account.emoji,
            balance: NSDecimalNumber(decimal: account.balance).stringValue,
            currency: account.currency
        )
    }

    private static func allowsReadFallback(for error: Error) -> Bool {
        (error as? NetworkError)?.allowsLocalFallback == true
    }

    private static func allowsIdempotentDeferral(for error: Error) -> Bool {
        (error as? NetworkError)?.allowsIdempotentMutationDeferral == true
    }

    private static func logCacheError(_ error: Error, operation: String) {
        logger.error(
            "Local cache failed during \(operation, privacy: .public): \(error.localizedDescription, privacy: .public)"
        )
    }
}
