//
//  TransactionRequestDTO.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

nonisolated struct TransactionRequestDTO: Encodable, Sendable {
    let accountId: Int
    let categoryId: Int
    let amount: String
    let transactionDate: Date
    let comment: String?

    private init(
        accountId: Int,
        categoryId: Int,
        amount: String,
        transactionDate: Date,
        comment: String?
    ) {
        self.accountId = accountId
        self.categoryId = categoryId
        self.amount = amount
        self.transactionDate = transactionDate
        self.comment = comment
    }

    init(
        account: BankAccount,
        category: Category,
        amount: Decimal,
        transactionDate: Date,
        comment: String?
    ) {
        self.init(
            accountId: account.id,
            categoryId: category.id,
            amount: NSDecimalNumber(decimal: amount).stringValue,
            transactionDate: transactionDate,
            comment: comment
        )
    }

    init(transaction: Transaction) {
        self.init(
            account: transaction.account,
            category: transaction.category,
            amount: transaction.amount,
            transactionDate: transaction.transactionDate,
            comment: transaction.comment
        )
    }

    // MARK: - Coding

    private enum CodingKeys: String, CodingKey {
        case accountId
        case categoryId
        case amount
        case transactionDate
        case comment
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encode(
            accountId,
            forKey: .accountId
        )
        try container.encode(
            categoryId,
            forKey: .categoryId
        )
        try container.encode(
            amount,
            forKey: .amount
        )
        try container.encode(
            transactionDate,
            forKey: .transactionDate
        )

        if let comment {
            try container.encode(
                comment,
                forKey: .comment
            )
        } else {
            try container.encodeNil(forKey: .comment)
        }
    }
}
