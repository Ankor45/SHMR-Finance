//
//  FinanceDataProviding.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 15.07.2026.
//

import Foundation

typealias FinanceDataProviding =
    CategoryDataProviding
  & AccountDataProviding
  & TransactionDataProviding

nonisolated protocol CategoryDataProviding: Sendable {
    func fetchCategories() async throws -> [CategoryDTO]
    func fetchCategories(direction: Direction) async throws -> [CategoryDTO]
}

nonisolated protocol AccountDataProviding: Sendable {
    func fetchAccounts() async throws -> [BankAccountDTO]
    func updateAccount(
        id: Int,
        request: AccountUpdateRequestDTO
    ) async throws -> BankAccountDTO
}

nonisolated protocol TransactionDataProviding: Sendable {
    func fetchTransactions(
        accountId: Int,
        from: Date,
        to: Date
    ) async throws -> [TransactionResponseDTO]
    func createTransaction(
        _ request: TransactionRequestDTO
    ) async throws -> TransactionDTO
    func updateTransaction(
        id: Int,
        request: TransactionRequestDTO
    ) async throws -> TransactionResponseDTO
    func deleteTransaction(id: Int) async throws
}
