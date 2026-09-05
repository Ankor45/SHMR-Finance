//
//  TransactionLocalOverlay.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

nonisolated enum TransactionLocalOverlay {
    static func makeUpdatedTransaction(
        _ existingTransaction: Transaction,
        account: BankAccount,
        category: Category,
        amount: Decimal,
        transactionDate: Date,
        comment: String?,
        timestamp: Date
    ) -> Transaction {
        Transaction(
            id: existingTransaction.id,
            account: account,
            category: category,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: existingTransaction.createdAt,
            updatedAt: timestamp
        )
    }

    static func overlay(
        _ pendingChanges: [PendingTransactionChange],
        on transactions: [Transaction],
        accountId: Int,
        from: Date,
        to: Date
    ) -> [Transaction] {
        var transactionsByID = Dictionary(
            uniqueKeysWithValues: transactions.map { ($0.id, $0) }
        )

        for change in pendingChanges {
            transactionsByID[change.transactionId] = nil

            guard
                change.action != .delete,
                change.action != .invalid,
                let transaction = change.transaction
            else {
                continue
            }
            transactionsByID[transaction.id] = transaction
        }

        return transactionsByID.values
            .filter {
                $0.account.id == accountId
                    && $0.transactionDate >= from
                    && $0.transactionDate <= to
            }
            .sorted { $0.transactionDate < $1.transactionDate }
    }
}
