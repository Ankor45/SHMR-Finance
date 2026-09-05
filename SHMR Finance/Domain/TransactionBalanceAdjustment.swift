//
//  TransactionBalanceAdjustment.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

nonisolated enum TransactionBalanceAdjustment {
    static func calculate(
        removing oldTransaction: Transaction?,
        adding newTransaction: Transaction?
    ) -> [Int: Decimal] {
        var deltasByAccountID: [Int: Decimal] = [:]

        if let oldTransaction {
            deltasByAccountID[oldTransaction.account.id, default: .zero]
                -= signedAmount(of: oldTransaction)
        }
        if let newTransaction {
            deltasByAccountID[newTransaction.account.id, default: .zero]
                += signedAmount(of: newTransaction)
        }

        return deltasByAccountID.filter { $0.value != .zero }
    }

    private static func signedAmount(
        of transaction: Transaction
    ) -> Decimal {
        transaction.direction == .income
            ? transaction.amount
            : -transaction.amount
    }
}
