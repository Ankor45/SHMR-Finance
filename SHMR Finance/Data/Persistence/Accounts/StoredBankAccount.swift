//
//  StoredBankAccount.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation
import SwiftData

@Model
nonisolated final class StoredBankAccount {
    @Attribute(.unique) var accountId: Int
    var userId: Int
    var name: String
    var emoji: String
    var balance: String
    var currency: String
    var createdAt: String
    var updatedAt: String

    init(account: BankAccount) {
        accountId = account.id
        userId = account.userId
        name = account.name
        emoji = account.emoji
        balance = Self.string(from: account.balance)
        currency = account.currency
        createdAt = account.createdAt
        updatedAt = account.updatedAt
    }

    func update(with account: BankAccount) {
        userId = account.userId
        name = account.name
        emoji = account.emoji
        balance = Self.string(from: account.balance)
        currency = account.currency
        createdAt = account.createdAt
        updatedAt = account.updatedAt
    }

    func toDomain() throws -> BankAccount {
        guard let balance = PersistenceDecimalCodec.decimal(
            from: balance
        ) else {
            throw FinanceStorageError.invalidStoredAccount(id: accountId)
        }

        return BankAccount(
            id: accountId,
            userId: userId,
            name: name,
            emoji: emoji,
            balance: balance,
            currency: currency,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private static func string(from decimal: Decimal) -> String {
        PersistenceDecimalCodec.string(from: decimal)
    }
}
