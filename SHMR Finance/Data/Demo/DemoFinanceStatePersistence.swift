//
//  DemoFinanceStatePersistence.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 04.09.2026.
//

import Foundation
import OSLog

private nonisolated enum Constants {
    static let seedResourceName = "DemoFinanceSeed"
    static let jsonExtension = "json"
    static let directoryName = "SHMRFinance/Demo"
    static let stateFileName = "finance-state.json"
}

nonisolated struct DemoFinanceStatePersistence: Sendable {
    // MARK: - Private Properties

    private let seedURL: URL
    private let stateURL: URL

    private static let logger = AppLogger.make(
        category: "DemoFinanceStatePersistence"
    )

    // MARK: - Factory Methods

    @concurrent
    static func make(
        bundle: Bundle = .main
    ) async throws -> DemoFinanceStatePersistence {
        guard let seedURL = bundle.url(
            forResource: Constants.seedResourceName,
            withExtension: Constants.jsonExtension
        ) else {
            throw DemoFinanceDataProviderError.seedNotFound
        }

        let applicationSupportURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directoryURL = applicationSupportURL
            .appending(
                path: Constants.directoryName,
                directoryHint: .isDirectory
            )

        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        return DemoFinanceStatePersistence(
            seedURL: seedURL,
            stateURL: directoryURL.appending(
                path: Constants.stateFileName,
                directoryHint: .notDirectory
            )
        )
    }

    // MARK: - Initializers

    init(seedURL: URL, stateURL: URL) {
        self.seedURL = seedURL
        self.stateURL = stateURL
    }

    // MARK: - Methods

    @concurrent
    func load(now: Date) async throws -> DemoFinanceState {
        guard FileManager.default.fileExists(
            atPath: stateURL.path(percentEncoded: false)
        ) else {
            return try restoreInitialState(now: now)
        }

        do {
            return try decodeState(from: stateURL)
        } catch {
            Self.logReadError(error, source: stateURL)
            return try restoreInitialState(now: now)
        }
    }

    func save(_ state: DemoFinanceState) throws {
        try encode(state).write(to: stateURL, options: .atomic)
    }

    // MARK: - Private Methods

    private func encode(_ state: DemoFinanceState) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970

        return try encoder.encode(state)
    }

    private func decodeState(from url: URL) throws -> DemoFinanceState {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(
            DemoFinanceState.self,
            from: Data(contentsOf: url)
        )
    }

    private func restoreInitialState(now: Date) throws -> DemoFinanceState {
        let state = try makeInitialState(now: now)
        try save(state)
        return state
    }

    private func makeInitialState(now: Date) throws -> DemoFinanceState {
        let seed = try JSONDecoder().decode(
            DemoFinanceSeed.self,
            from: Data(contentsOf: seedURL)
        )
        let calendar = Calendar.autoupdatingCurrent
        let transactions = try seed.transactions.map { transaction in
            guard
                transaction.daysAgo >= .zero,
                let day = calendar.date(
                    byAdding: .day,
                    value: -transaction.daysAgo,
                    to: calendar.startOfDay(for: now)
                ),
                let transactionDate = calendar.date(
                    bySettingHour: transaction.hour,
                    minute: transaction.minute,
                    second: .zero,
                    of: day
                )
            else {
                throw DemoFinanceDataProviderError.invalidSeed
            }

            return DemoTransactionRecord(
                id: transaction.id,
                accountId: transaction.accountId,
                categoryId: transaction.categoryId,
                amount: transaction.amount,
                transactionDate: transactionDate,
                comment: transaction.comment,
                createdAt: transactionDate,
                updatedAt: transactionDate
            )
        }

        return DemoFinanceState(
            nextTransactionID: (transactions.map(\.id).max() ?? .zero) + 1,
            accounts: seed.accounts,
            categories: seed.categories,
            transactions: transactions
        )
    }

    private static func logReadError(_ error: Error, source: URL) {
        let fileName = source.lastPathComponent
        let description = error.localizedDescription
        logger.error(
            "Failed to read \(fileName, privacy: .public): \(description, privacy: .public)"
        )
    }
}
