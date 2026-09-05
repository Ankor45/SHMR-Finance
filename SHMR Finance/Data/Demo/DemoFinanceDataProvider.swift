//
//  DemoFinanceDataProvider.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 04.09.2026.
//

import Foundation

actor DemoFinanceDataProvider: FinanceDataProviding {
    // MARK: - Private Properties

    private let persistence: DemoFinanceStatePersistence
    private let now: @Sendable () -> Date
    private var state: DemoFinanceState

    // MARK: - Factory Methods

    static func make(
        now: @escaping @Sendable () -> Date = { .now }
    ) async throws -> DemoFinanceDataProvider {
        let persistence = try await DemoFinanceStatePersistence.make()
        return try await make(
            persistence: persistence,
            now: now
        )
    }

    static func make(
        persistence: DemoFinanceStatePersistence,
        now: @escaping @Sendable () -> Date = { .now }
    ) async throws -> DemoFinanceDataProvider {
        let state = try await persistence.load(now: now())
        return DemoFinanceDataProvider(
            persistence: persistence,
            now: now,
            state: state
        )
    }

    // MARK: - Initializers

    private init(
        persistence: DemoFinanceStatePersistence,
        now: @escaping @Sendable () -> Date,
        state: DemoFinanceState
    ) {
        self.persistence = persistence
        self.now = now
        self.state = state
    }

    // MARK: - CategoryDataProviding

    func fetchCategories() -> [CategoryDTO] {
        state.categoryDTOs()
    }

    func fetchCategories(
        direction: Direction
    ) -> [CategoryDTO] {
        state.categoryDTOs(direction: direction)
    }

    // MARK: - AccountDataProviding

    func fetchAccounts() -> [BankAccountDTO] {
        state.accountDTOs()
    }

    func updateAccount(
        id: Int,
        request: AccountUpdateRequestDTO
    ) async throws -> BankAccountDTO {
        try commit { state in
            try state.updateAccount(
                id: id,
                request: request,
                timestamp: now()
            )
        }
    }

    // MARK: - TransactionDataProviding

    func fetchTransactions(
        accountId: Int,
        from: Date,
        to: Date
    ) throws -> [TransactionResponseDTO] {
        try state.transactionDTOs(
            accountID: accountId,
            from: from,
            to: to
        )
    }

    func createTransaction(
        _ request: TransactionRequestDTO
    ) async throws -> TransactionDTO {
        try commit { state in
            try state.createTransaction(
                request,
                timestamp: now()
            )
        }
    }

    func updateTransaction(
        id: Int,
        request: TransactionRequestDTO
    ) async throws -> TransactionResponseDTO {
        try commit { state in
            try state.updateTransaction(
                id: id,
                request: request,
                timestamp: now()
            )
        }
    }

    func deleteTransaction(id: Int) async throws {
        try commit { state in
            try state.deleteTransaction(
                id: id,
                timestamp: now()
            )
        }
    }

    // MARK: - Private Methods

    private func commit<Result: Sendable>(
        _ mutation: (inout DemoFinanceState) throws -> Result
    ) throws -> Result {
        var updatedState = state
        let result = try mutation(&updatedState)

        try persistence.save(updatedState)
        state = updatedState
        return result
    }
}
