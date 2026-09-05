//
//  StoredTransaction.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation
import SwiftData

@Model
nonisolated final class StoredTransaction {
    @Attribute(.unique) var transactionId: Int

    var accountId: Int
    var accountUserId: Int
    var accountName: String
    var accountEmoji: String
    var accountBalance: String
    var accountCurrency: String
    var accountCreatedAt: String
    var accountUpdatedAt: String

    var categoryId: Int
    var categoryName: String
    var categoryEmoji: String
    var categoryIsIncome: Bool

    var amount: String
    var transactionDate: Date
    var comment: String?
    var createdAt: Date
    var updatedAt: Date

    init(transaction: Transaction) {
        transactionId = transaction.id

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

    func update(with transaction: Transaction) {
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
            throw FinanceStorageError.invalidStoredTransaction(
                id: transactionId
            )
        }

        let account = BankAccount(
            id: accountId,
            userId: accountUserId,
            name: accountName,
            emoji: accountEmoji,
            balance: accountBalance,
            currency: accountCurrency,
            createdAt: accountCreatedAt,
            updatedAt: accountUpdatedAt
        )
        let category = Category(
            id: categoryId,
            name: categoryName,
            emoji: categoryEmoji,
            direction: categoryIsIncome ? .income : .outcome
        )

        return Transaction(
            id: transactionId,
            account: account,
            category: category,
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
