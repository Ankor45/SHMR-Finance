//
//  TransactionBalanceAdjustmentTests.swift
//  SHMR FinanceTests
//
//  Created by Andrei Kovryzhenko on 04.09.2026.
//

import Foundation
import Testing
@testable import SHMR_Finance

struct TransactionBalanceAdjustmentTests {
    // MARK: - Creation

    @Test func calculate_creationAppliesSignedAmount() {
        let income = makeTransaction(
            accountID: 1,
            amount: 100,
            direction: .income
        )
        let outcome = makeTransaction(
            accountID: 2,
            amount: 40,
            direction: .outcome
        )

        #expect(
            TransactionBalanceAdjustment.calculate(
                removing: nil,
                adding: income
            ) == [1: Decimal(100)]
        )
        #expect(
            TransactionBalanceAdjustment.calculate(
                removing: nil,
                adding: outcome
            ) == [2: Decimal(-40)]
        )
    }

    // MARK: - Deletion

    @Test func calculate_deletionReversesSignedAmount() {
        let income = makeTransaction(
            accountID: 1,
            amount: 100,
            direction: .income
        )
        let outcome = makeTransaction(
            accountID: 2,
            amount: 40,
            direction: .outcome
        )

        #expect(
            TransactionBalanceAdjustment.calculate(
                removing: income,
                adding: nil
            ) == [1: Decimal(-100)]
        )
        #expect(
            TransactionBalanceAdjustment.calculate(
                removing: outcome,
                adding: nil
            ) == [2: Decimal(40)]
        )
    }

    // MARK: - Editing

    @Test func calculate_amountChangeAppliesOnlyDifference() {
        let oldTransaction = makeTransaction(
            accountID: 1,
            amount: 100,
            direction: .outcome
        )
        let newTransaction = makeTransaction(
            accountID: 1,
            amount: 150,
            direction: .outcome
        )

        let result = TransactionBalanceAdjustment.calculate(
            removing: oldTransaction,
            adding: newTransaction
        )

        #expect(result == [1: Decimal(-50)])
    }

    @Test func calculate_directionChangeReversesOldEffect() {
        let oldTransaction = makeTransaction(
            accountID: 1,
            amount: 100,
            direction: .outcome
        )
        let newTransaction = makeTransaction(
            accountID: 1,
            amount: 100,
            direction: .income
        )

        let result = TransactionBalanceAdjustment.calculate(
            removing: oldTransaction,
            adding: newTransaction
        )

        #expect(result == [1: Decimal(200)])
    }

    @Test func calculate_accountChangeAdjustsBothAccounts() {
        let oldTransaction = makeTransaction(
            accountID: 1,
            amount: 100,
            direction: .outcome
        )
        let newTransaction = makeTransaction(
            accountID: 2,
            amount: 100,
            direction: .outcome
        )

        let result = TransactionBalanceAdjustment.calculate(
            removing: oldTransaction,
            adding: newTransaction
        )

        #expect(
            result == [
                1: Decimal(100),
                2: Decimal(-100)
            ]
        )
    }

    // MARK: - Private Methods

    private func makeTransaction(
        accountID: Int,
        amount: Decimal,
        direction: Direction
    ) -> Transaction {
        Transaction(
            id: 1,
            account: BankAccount(
                id: accountID,
                userId: 1,
                name: "Test account",
                emoji: "💳",
                balance: .zero,
                currency: "RUB",
                createdAt: "",
                updatedAt: ""
            ),
            category: Category(
                id: 1,
                name: "Test category",
                emoji: "🧪",
                direction: direction
            ),
            amount: amount,
            transactionDate: .distantPast,
            comment: nil,
            createdAt: .distantPast,
            updatedAt: .distantPast
        )
    }
}
