//
//  DemoFinanceDataProviderTests.swift
//  SHMR FinanceTests
//
//  Created by Andrei Kovryzhenko on 04.09.2026.
//

import Foundation
import Testing
@testable import SHMR_Finance

private enum Constants {
    static let sourceAccountID = 1
    static let destinationAccountID = 2
    static let expenseCategoryID = 4
    static let seededTransactionID = 1
    static let transactionAmount = Decimal(100)
    static let concurrentMutationCount = 10
    static let testDate = Date(timeIntervalSince1970: 1_750_000_000)
    static let seedResourceName = "DemoFinanceSeed"
    static let jsonExtension = "json"
    static let stateFilePrefix = "demo-finance-"
    static let spacedDirectoryPrefix = "Demo Finance "
    static let corruptedState = Data("{".utf8)
}

struct DemoFinanceDataProviderTests {
    // MARK: - Transaction Mutations

    @Test func createAndDeleteTransaction_restoresAccountBalance() async throws {
        let context = try await makeContext()
        defer { context.removeState() }

        let initialBalance = try await balance(
            accountID: Constants.sourceAccountID,
            provider: context.provider
        )
        let request = try await makeRequest(
            provider: context.provider,
            accountID: Constants.sourceAccountID,
            categoryID: Constants.expenseCategoryID,
            amount: Constants.transactionAmount
        )

        let transaction = try await context.provider.createTransaction(request)

        #expect(
            try await balance(
                accountID: Constants.sourceAccountID,
                provider: context.provider
            ) == initialBalance - Constants.transactionAmount
        )

        try await context.provider.deleteTransaction(id: transaction.id)

        #expect(
            try await balance(
                accountID: Constants.sourceAccountID,
                provider: context.provider
            ) == initialBalance
        )
    }

    @Test func updateTransaction_movesBalanceBetweenAccounts() async throws {
        let context = try await makeContext()
        defer { context.removeState() }

        let sourceBalance = try await balance(
            accountID: Constants.sourceAccountID,
            provider: context.provider
        )
        let destinationBalance = try await balance(
            accountID: Constants.destinationAccountID,
            provider: context.provider
        )
        let transactions = try await context.provider.fetchTransactions(
            accountId: Constants.sourceAccountID,
            from: .distantPast,
            to: .distantFuture
        )
        guard let transaction = transactions.first(
            where: { $0.id == Constants.seededTransactionID }
        ) else {
            throw TestError.missingFixture
        }
        guard let amount = Decimal(
            string: transaction.amount,
            locale: AppLocale.posix
        ) else {
            throw TestError.invalidAmount
        }
        let request = try await makeRequest(
            provider: context.provider,
            accountID: Constants.destinationAccountID,
            categoryID: transaction.category.id,
            amount: amount
        )

        let updated = try await context.provider.updateTransaction(
            id: transaction.id,
            request: request
        )

        #expect(updated.account.id == Constants.destinationAccountID)
        #expect(
            try await balance(
                accountID: Constants.sourceAccountID,
                provider: context.provider
            ) == sourceBalance + amount
        )
        #expect(
            try await balance(
                accountID: Constants.destinationAccountID,
                provider: context.provider
            ) == destinationBalance - amount
        )
    }

    @Test func concurrentTransactions_areAllPersisted() async throws {
        let context = try await makeContext()
        defer { context.removeState() }

        let initialBalance = try await balance(
            accountID: Constants.sourceAccountID,
            provider: context.provider
        )
        let request = try await makeRequest(
            provider: context.provider,
            accountID: Constants.sourceAccountID,
            categoryID: Constants.expenseCategoryID,
            amount: Constants.transactionAmount
        )
        let createdIDs = try await withThrowingTaskGroup(
            of: Int.self,
            returning: [Int].self
        ) { group in
            for _ in 0..<Constants.concurrentMutationCount {
                group.addTask {
                    try await context.provider
                        .createTransaction(request)
                        .id
                }
            }

            return try await group.reduce(into: []) { ids, id in
                ids.append(id)
            }
        }
        let restoredProvider = try await DemoFinanceDataProvider.make(
            persistence: context.persistence,
            now: { Constants.testDate }
        )
        let restoredTransactions = try await restoredProvider
            .fetchTransactions(
                accountId: Constants.sourceAccountID,
                from: .distantPast,
                to: .distantFuture
            )
        let restoredBalance = try await balance(
            accountID: Constants.sourceAccountID,
            provider: restoredProvider
        )
        let expectedBalance = initialBalance
            - Constants.transactionAmount
            * Decimal(Constants.concurrentMutationCount)

        #expect(Set(createdIDs).count == Constants.concurrentMutationCount)
        #expect(
            createdIDs.allSatisfy { createdID in
                restoredTransactions.contains { $0.id == createdID }
            }
        )
        #expect(restoredBalance == expectedBalance)
    }

    // MARK: - Persistence

    @Test func createTransaction_persistsBetweenProviderInstances() async throws {
        let context = try await makeContext()
        defer { context.removeState() }

        let request = try await makeRequest(
            provider: context.provider,
            accountID: Constants.sourceAccountID,
            categoryID: Constants.expenseCategoryID,
            amount: Constants.transactionAmount
        )
        let created = try await context.provider.createTransaction(request)
        let date = Constants.testDate
        let restoredProvider = try await DemoFinanceDataProvider.make(
            persistence: context.persistence,
            now: { date }
        )

        let restoredTransactions = try await restoredProvider.fetchTransactions(
            accountId: Constants.sourceAccountID,
            from: .distantPast,
            to: .distantFuture
        )
        let restoredBalance = try await balance(
            accountID: Constants.sourceAccountID,
            provider: restoredProvider
        )
        let currentBalance = try await balance(
            accountID: Constants.sourceAccountID,
            provider: context.provider
        )

        #expect(restoredTransactions.contains { $0.id == created.id })
        #expect(restoredBalance == currentBalance)
    }

    @Test func persistedState_isFoundWhenPathContainsSpaces() async throws {
        let directoryURL = FileManager.default.temporaryDirectory.appending(
            path: Constants.spacedDirectoryPrefix + UUID().uuidString,
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let context = try await makeContext(in: directoryURL)
        let request = try await makeRequest(
            provider: context.provider,
            accountID: Constants.sourceAccountID,
            categoryID: Constants.expenseCategoryID,
            amount: Constants.transactionAmount
        )
        let created = try await context.provider.createTransaction(request)
        let restoredProvider = try await DemoFinanceDataProvider.make(
            persistence: context.persistence,
            now: { Constants.testDate }
        )
        let restoredTransactions = try await restoredProvider
            .fetchTransactions(
                accountId: Constants.sourceAccountID,
                from: .distantPast,
                to: .distantFuture
            )

        #expect(restoredTransactions.contains { $0.id == created.id })
    }

    @Test func corruptedState_restoresSeed() async throws {
        let context = try await makeContext()
        defer { context.removeState() }

        let request = try await makeRequest(
            provider: context.provider,
            accountID: Constants.sourceAccountID,
            categoryID: Constants.expenseCategoryID,
            amount: Constants.transactionAmount
        )
        let created = try await context.provider.createTransaction(request)

        try Constants.corruptedState.write(
            to: context.stateURL,
            options: .atomic
        )

        let restoredProvider = try await DemoFinanceDataProvider.make(
            persistence: context.persistence,
            now: { Constants.testDate }
        )
        let restoredTransactions = try await restoredProvider.fetchTransactions(
            accountId: Constants.sourceAccountID,
            from: .distantPast,
            to: .distantFuture
        )
        #expect(
            restoredTransactions.contains {
                $0.id == Constants.seededTransactionID
            }
        )
        #expect(
            !restoredTransactions.contains { $0.id == created.id }
        )
    }

    // MARK: - Private Methods

    private func makeContext(
        in directoryURL: URL = FileManager.default.temporaryDirectory
    ) async throws -> TestContext {
        guard let seedURL = Bundle.main.url(
            forResource: Constants.seedResourceName,
            withExtension: Constants.jsonExtension
        ) else {
            throw TestError.missingFixture
        }

        let stateFileName = Constants.stateFilePrefix
            + UUID().uuidString
            + ".\(Constants.jsonExtension)"
        let stateURL = directoryURL.appending(
            path: stateFileName,
            directoryHint: .notDirectory
        )
        let persistence = DemoFinanceStatePersistence(
            seedURL: seedURL,
            stateURL: stateURL
        )
        let date = Constants.testDate
        let provider = try await DemoFinanceDataProvider.make(
            persistence: persistence,
            now: { date }
        )

        return TestContext(
            provider: provider,
            persistence: persistence,
            stateURL: stateURL
        )
    }

    private func makeRequest(
        provider: DemoFinanceDataProvider,
        accountID: Int,
        categoryID: Int,
        amount: Decimal
    ) async throws -> TransactionRequestDTO {
        guard let accountDTO = await provider.fetchAccounts().first(
            where: { $0.id == accountID }
        ) else {
            throw TestError.missingFixture
        }
        guard let categoryDTO = await provider.fetchCategories().first(
            where: { $0.id == categoryID }
        ) else {
            throw TestError.missingFixture
        }

        return TransactionRequestDTO(
            account: try accountDTO.toDomain(),
            category: categoryDTO.toDomain(),
            amount: amount,
            transactionDate: Constants.testDate,
            comment: nil
        )
    }

    private func balance(
        accountID: Int,
        provider: DemoFinanceDataProvider
    ) async throws -> Decimal {
        guard let account = await provider.fetchAccounts().first(
            where: { $0.id == accountID }
        ) else {
            throw TestError.missingFixture
        }
        guard let balance = Decimal(
            string: account.balance,
            locale: AppLocale.posix
        ) else {
            throw TestError.invalidAmount
        }
        return balance
    }
}

private struct TestContext {
    let provider: DemoFinanceDataProvider
    let persistence: DemoFinanceStatePersistence
    let stateURL: URL

    func removeState() {
        try? FileManager.default.removeItem(at: stateURL)
    }
}

private enum TestError: Error {
    case missingFixture
    case invalidAmount
}
