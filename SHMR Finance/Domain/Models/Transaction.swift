//
//  Transaction.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 15.07.2026.
//

import Foundation

nonisolated struct Transaction: Identifiable, Equatable, Sendable {
    let id: Int
    let account: BankAccount
    let category: Category
    let amount: Decimal
    let transactionDate: Date
    let comment: String?
    let createdAt: Date
    let updatedAt: Date

    var direction: Direction {
        category.direction
    }
}
