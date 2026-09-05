//
//  FinanceServiceProviding.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 15.07.2026.
//

import Foundation

typealias FinanceServiceProviding =
    CategoryServiceProviding &
    AccountServiceProviding &
    TransactionServiceProviding

typealias TransactionsScreenServiceProviding =
    TransactionServiceProviding &
    CategoryServiceProviding

nonisolated protocol CategoryServiceProviding: Sendable {
    func getCategories() async throws -> [Category]
    func getCategories(direction: Direction) async throws -> [Category]
}

nonisolated protocol AccountServiceProviding: Sendable {
    func getAccounts() async throws -> [BankAccount]
    func updateAccount(_ account: BankAccount) async throws -> BankAccount
}

nonisolated protocol TransactionServiceProviding: Sendable {
    func getTransactions(
        account: BankAccount,
        from: Date,
        to: Date
    ) async throws -> [Transaction]
    func createTransaction(
        account: BankAccount,
        category: Category,
        amount: Decimal,
        transactionDate: Date,
        comment: String?
    ) async throws -> Transaction
    func updateTransaction(
        _ transaction: Transaction,
        account: BankAccount,
        category: Category,
        amount: Decimal,
        transactionDate: Date,
        comment: String?
    ) async throws -> Transaction
    func deleteTransaction(_ transaction: Transaction) async throws
}
