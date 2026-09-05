//
//  FinanceStorageSnapshot.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation

nonisolated struct FinanceStorageSnapshot: Sendable {
    let transactions: [Transaction]
    let accounts: [BankAccount]
    let categories: [Category]
    let pendingTransactions: [PendingTransactionStorageSnapshot]
    let pendingAccounts: [PendingAccountStorageSnapshot]
}

nonisolated struct PendingTransactionStorageSnapshot: Equatable, Sendable {
    let transactionId: Int
    let actionRawValue: String
    let payload: Data?
    let balanceAdjustmentPayload: Data
    let insertedAt: Date
    let revision: UUID
    let stateRawValue: String
    let failureMessage: String?
}

nonisolated struct PendingAccountStorageSnapshot: Equatable, Sendable {
    let accountId: Int
    let payload: Data
    let insertedAt: Date
    let revision: UUID
    let stateRawValue: String
    let failureMessage: String?
}
