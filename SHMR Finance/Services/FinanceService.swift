//
//  FinanceService.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 15.07.2026.
//

import Foundation

nonisolated final class FinanceService:
    FinanceServiceProviding,
    Sendable {
    // MARK: - Private Properties
    private let categoriesService: any CategoryServiceProviding
    private let accountsService: any AccountServiceProviding
    private let transactionsService: any TransactionServiceProviding

    // MARK: - Initializers
    init(
        dataProvider: any FinanceDataProviding,
        localStorage: any FinanceLocalStorage,
        synchronizationStatus: any SynchronizationStatusReporting,
        dataSourceStatus: any DataSourceStatusReporting
    ) {
        categoriesService = CategoriesService(
            dataProvider: dataProvider,
            storage: localStorage,
            dataSourceStatus: dataSourceStatus
        )
        let synchronizer = FinanceSynchronizer(
            dataProvider: dataProvider,
            localStorage: localStorage,
            statusReporter: synchronizationStatus
        )
        let transactionsService = TransactionsService(
            dataProvider: dataProvider,
            localStorage: localStorage,
            synchronizer: synchronizer,
            dataSourceStatus: dataSourceStatus
        )
        self.transactionsService = transactionsService
        accountsService = BankAccountsService(
            dataProvider: dataProvider,
            localStorage: localStorage,
            synchronizer: synchronizer,
            dataSourceStatus: dataSourceStatus
        )
    }

    // MARK: - Public Methods
    func getCategories() async throws -> [Category] {
        try await categoriesService.getCategories()
    }

    func getCategories(direction: Direction) async throws -> [Category] {
        try await categoriesService.getCategories(direction: direction)
    }

    // MARK: - Account Services
    func getAccounts() async throws -> [BankAccount] {
        try await accountsService.getAccounts()
    }

    func updateAccount(_ account: BankAccount) async throws -> BankAccount {
        try await accountsService.updateAccount(account)
    }

    // MARK: - Transaction Services
    func getTransactions(
        account: BankAccount,
        from: Date,
        to: Date
    ) async throws -> [Transaction] {
        try await transactionsService.getTransactions(
            account: account,
            from: from,
            to: to
        )
    }

    func createTransaction(
        account: BankAccount,
        category: Category,
        amount: Decimal,
        transactionDate: Date,
        comment: String?
    ) async throws -> Transaction {
        try await transactionsService.createTransaction(
            account: account,
            category: category,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment
        )
    }

    func updateTransaction(
        _ transaction: Transaction,
        account: BankAccount,
        category: Category,
        amount: Decimal,
        transactionDate: Date,
        comment: String?
    ) async throws -> Transaction {
        try await transactionsService.updateTransaction(
            transaction,
            account: account,
            category: category,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment
        )
    }

    func deleteTransaction(_ transaction: Transaction) async throws {
        try await transactionsService.deleteTransaction(transaction)
    }
}
