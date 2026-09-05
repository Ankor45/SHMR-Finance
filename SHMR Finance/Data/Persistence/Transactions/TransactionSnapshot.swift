//
//  TransactionSnapshot.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

nonisolated struct TransactionSnapshot: Codable, Sendable {
    let id: Int

    let accountId: Int
    let accountUserId: Int
    let accountName: String
    let accountEmoji: String
    let accountBalance: String
    let accountCurrency: String
    let accountCreatedAt: String
    let accountUpdatedAt: String

    let categoryId: Int
    let categoryName: String
    let categoryEmoji: String
    let categoryIsIncome: Bool

    let amount: String
    let transactionDate: Date
    let comment: String?
    let createdAt: Date
    let updatedAt: Date

    init(transaction: Transaction) {
        id = transaction.id

        accountId = transaction.account.id
        accountUserId = transaction.account.userId
        accountName = transaction.account.name
        accountEmoji = transaction.account.emoji
        accountBalance = Self.string(from: transaction.account.balance)
        accountCurrency = transaction.account.currency
        accountCreatedAt = transaction.account.createdAt
        accountUpdatedAt = transaction.account.updatedAt

        categoryId = transaction.category.id
        categoryName = transaction.category.name
        categoryEmoji = String(transaction.category.emoji)
        categoryIsIncome = transaction.category.direction == .income

        amount = Self.string(from: transaction.amount)
        transactionDate = transaction.transactionDate
        comment = transaction.comment
        createdAt = transaction.createdAt
        updatedAt = transaction.updatedAt
    }

    func toDomain() throws -> Transaction {
        guard
            let accountBalance = Self.decimal(from: accountBalance),
            let amount = Self.decimal(from: amount),
            let categoryEmoji = categoryEmoji.first
        else {
            throw FinanceStorageError.invalidPendingTransaction(id: id)
        }

        return Transaction(
            id: id,
            account: BankAccount(
                id: accountId,
                userId: accountUserId,
                name: accountName,
                emoji: accountEmoji,
                balance: accountBalance,
                currency: accountCurrency,
                createdAt: accountCreatedAt,
                updatedAt: accountUpdatedAt
            ),
            category: Category(
                id: categoryId,
                name: categoryName,
                emoji: categoryEmoji,
                direction: categoryIsIncome ? .income : .outcome
            ),
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private static func string(from decimal: Decimal) -> String {
        PersistenceDecimalCodec.string(from: decimal)
    }

    private static func decimal(from string: String) -> Decimal? {
        PersistenceDecimalCodec.decimal(from: string)
    }
}
