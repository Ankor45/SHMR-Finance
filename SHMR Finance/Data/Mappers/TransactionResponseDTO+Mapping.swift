//
//  TransactionResponseDTO+Mapping.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

nonisolated extension TransactionResponseDTO {
    func toDomain(
        account sourceAccount: BankAccount
    ) throws -> Transaction {
        guard account.id == sourceAccount.id else {
            throw TransactionMappingError.unexpectedAccount(
                expectedID: sourceAccount.id,
                actualID: account.id
            )
        }

        guard let balance = Decimal(
            string: account.balance,
            locale: AppLocale.posix
        ) else {
            throw TransactionMappingError.invalidBalance(
                account.balance
            )
        }

        guard let amount = Decimal(
            string: amount,
            locale: AppLocale.posix
        ) else {
            throw TransactionMappingError.invalidAmount(amount)
        }

        let resolvedAccount = BankAccount(
            id: sourceAccount.id,
            userId: sourceAccount.userId,
            name: account.name,
            emoji: account.emoji,
            balance: balance,
            currency: account.currency,
            createdAt: sourceAccount.createdAt,
            updatedAt: sourceAccount.updatedAt
        )

        return Transaction(
            id: id,
            account: resolvedAccount,
            category: category.toDomain(),
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
