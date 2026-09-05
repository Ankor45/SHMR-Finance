//
//  NetworkFinanceDataProvider.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

private nonisolated enum APIPath {
    static let accounts = "accounts"
    static let categories = "categories"
    static let transactions = "transactions"

    static func account(id: Int) -> String {
        "\(accounts)/\(id)"
    }

    static func categories(isIncome: Bool) -> String {
        "\(categories)/type/\(isIncome)"
    }

    static func transaction(id: Int) -> String {
        "\(transactions)/\(id)"
    }

    static func transactions(accountId: Int) -> String {
        "\(transactions)/account/\(accountId)/period"
    }
}

private nonisolated enum QueryName {
    static let startDate = "startDate"
    static let endDate = "endDate"
}

nonisolated final class NetworkFinanceDataProvider:
    FinanceDataProviding,
    Sendable {
    // MARK: - Private Properties

    private let client: NetworkClient

    // MARK: - Initializers

    init(client: NetworkClient) {
        self.client = client
    }

    // MARK: - CategoryDataProviding

    func fetchCategories() async throws -> [CategoryDTO] {
        try await client.request(
            NetworkRequest(
                path: APIPath.categories,
                method: .get
            )
        )
    }

    func fetchCategories(
        direction: Direction
    ) async throws -> [CategoryDTO] {
        try await client.request(
            NetworkRequest(
                path: APIPath.categories(
                    isIncome: direction == .income
                ),
                method: .get
            )
        )
    }

    // MARK: - AccountDataProviding

    func fetchAccounts() async throws -> [BankAccountDTO] {
        try await client.request(
            NetworkRequest(
                path: APIPath.accounts,
                method: .get
            )
        )
    }

    func updateAccount(
        id: Int,
        request: AccountUpdateRequestDTO
    ) async throws -> BankAccountDTO {
        try await client.request(
            NetworkRequest(
                path: APIPath.account(id: id),
                method: .put
            ),
            body: request
        )
    }

    // MARK: - TransactionDataProviding

    func fetchTransactions(
        accountId: Int,
        from: Date,
        to: Date
    ) async throws -> [TransactionResponseDTO] {
        let formatter = makeBackendDateFormatter()
        return try await client.request(
            NetworkRequest(
                path: APIPath.transactions(
                    accountId: accountId
                ),
                method: .get,
                queryItems: [
                    URLQueryItem(
                        name: QueryName.startDate,
                        value: formatter.string(from: from)
                    ),
                    URLQueryItem(
                        name: QueryName.endDate,
                        value: formatter.string(from: to)
                    )
                ]
            )
        )
    }

    func createTransaction(
        _ request: TransactionRequestDTO
    ) async throws -> TransactionDTO {
        try await client.request(
            NetworkRequest(
                path: APIPath.transactions,
                method: .post
            ),
            body: request
        )
    }

    func updateTransaction(
        id: Int,
        request: TransactionRequestDTO
    ) async throws -> TransactionResponseDTO {
        try await client.request(
            NetworkRequest(
                path: APIPath.transaction(id: id),
                method: .put
            ),
            body: request
        )
    }

    func deleteTransaction(id: Int) async throws {
        try await client.request(
            NetworkRequest(
                path: APIPath.transaction(id: id),
                method: .delete
            )
        )
    }

    // MARK: - Private Methods

    private func makeBackendDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = AppLocale.posix
        formatter.timeZone = TimeZone(secondsFromGMT: .zero)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}
