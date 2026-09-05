//
//  DemoFinanceState+Mutations.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 04.09.2026.
//

import Foundation

nonisolated extension DemoFinanceState {
    mutating func updateAccount(
        id: Int,
        request: AccountUpdateRequestDTO,
        timestamp: Date
    ) throws -> BankAccountDTO {
        guard let index = accounts.firstIndex(
            where: { $0.id == id }
        ) else {
            throw FinanceStorageError.accountNotFound(id: id)
        }

        accounts[index].name = request.name
        if let emoji = request.emoji {
            accounts[index].emoji = emoji
        }
        accounts[index].balance = request.balance
        accounts[index].currency = request.currency
        accounts[index].updatedAt = Self.timestamp(from: timestamp)
        return accounts[index].dto
    }

    mutating func createTransaction(
        _ request: TransactionRequestDTO,
        timestamp: Date
    ) throws -> TransactionDTO {
        try validate(request)

        let transaction = DemoTransactionRecord(
            id: nextTransactionID,
            accountId: request.accountId,
            categoryId: request.categoryId,
            amount: request.amount,
            transactionDate: request.transactionDate,
            comment: request.comment,
            createdAt: timestamp,
            updatedAt: timestamp
        )

        nextTransactionID += 1
        transactions.append(transaction)
        try adjustBalance(for: transaction, multiplier: 1, timestamp: timestamp)
        return transaction.dto
    }

    mutating func updateTransaction(
        id: Int,
        request: TransactionRequestDTO,
        timestamp: Date
    ) throws -> TransactionResponseDTO {
        try validate(request)

        guard let index = transactions.firstIndex(
            where: { $0.id == id }
        ) else {
            throw DemoFinanceDataProviderError.transactionNotFound(id: id)
        }

        let oldTransaction = transactions[index]
        try adjustBalance(
            for: oldTransaction,
            multiplier: -1,
            timestamp: timestamp
        )

        let transaction = DemoTransactionRecord(
            id: id,
            accountId: request.accountId,
            categoryId: request.categoryId,
            amount: request.amount,
            transactionDate: request.transactionDate,
            comment: request.comment,
            createdAt: oldTransaction.createdAt,
            updatedAt: timestamp
        )
        transactions[index] = transaction
        try adjustBalance(
            for: transaction,
            multiplier: 1,
            timestamp: timestamp
        )
        return try transaction.responseDTO(in: self)
    }

    mutating func deleteTransaction(
        id: Int,
        timestamp: Date
    ) throws {
        guard let index = transactions.firstIndex(
            where: { $0.id == id }
        ) else {
            return
        }

        let transaction = transactions.remove(at: index)
        try adjustBalance(
            for: transaction,
            multiplier: -1,
            timestamp: timestamp
        )
    }

    // MARK: - Private Methods

    private func validate(_ request: TransactionRequestDTO) throws {
        guard accounts.contains(
            where: { $0.id == request.accountId }
        ) else {
            throw FinanceStorageError.accountNotFound(id: request.accountId)
        }
        guard categories.contains(
            where: { $0.id == request.categoryId }
        ) else {
            throw TransactionMappingError.categoryNotFound(
                id: request.categoryId
            )
        }
        guard
            let amount = PersistenceDecimalCodec.decimal(
                from: request.amount
            ),
            amount > .zero
        else {
            throw TransactionMappingError.invalidAmount(request.amount)
        }
    }

    private mutating func adjustBalance(
        for transaction: DemoTransactionRecord,
        multiplier: Decimal,
        timestamp: Date
    ) throws {
        guard let accountIndex = accounts.firstIndex(
            where: { $0.id == transaction.accountId }
        ) else {
            throw FinanceStorageError.accountNotFound(
                id: transaction.accountId
            )
        }
        guard let category = categories.first(
            where: { $0.id == transaction.categoryId }
        ) else {
            throw TransactionMappingError.categoryNotFound(
                id: transaction.categoryId
            )
        }
        guard
            let balance = PersistenceDecimalCodec.decimal(
                from: accounts[accountIndex].balance
            ),
            let amount = PersistenceDecimalCodec.decimal(
                from: transaction.amount
            )
        else {
            throw DemoFinanceDataProviderError.invalidSeed
        }

        let signedAmount = category.isIncome ? amount : -amount
        let updatedBalance = balance + signedAmount * multiplier
        accounts[accountIndex].balance = PersistenceDecimalCodec.string(
            from: updatedBalance
        )
        accounts[accountIndex].updatedAt = Self.timestamp(from: timestamp)
    }

    private static func timestamp(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        return formatter.string(from: date)
    }
}
