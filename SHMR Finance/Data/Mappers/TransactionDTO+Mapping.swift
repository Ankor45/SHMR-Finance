//
//  TransactionDTO+Mapping.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 15.07.2026.
//

import Foundation

nonisolated extension TransactionDTO {
    func toDomain(
        accountsById: [Int: BankAccount],
        categoriesById: [Int: Category]
    ) throws -> Transaction {
        guard let account = accountsById[accountId] else {
            throw TransactionMappingError.accountNotFound(id: accountId)
        }
        guard let category = categoriesById[categoryId] else {
            throw TransactionMappingError.categoryNotFound(id: categoryId)
        }

        guard let amount = Decimal(
            string: amount,
            locale: AppLocale.posix
        ) else {
            throw TransactionMappingError.invalidAmount(amount)
        }

        return Transaction(
            id: id,
            account: account,
            category: category,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
