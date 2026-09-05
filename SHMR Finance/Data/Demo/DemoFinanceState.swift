//
//  DemoFinanceState.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 04.09.2026.
//

import Foundation

nonisolated struct DemoFinanceSeed: Decodable, Sendable {
    let accounts: [DemoAccountRecord]
    let categories: [DemoCategoryRecord]
    let transactions: [DemoTransactionSeed]
}

nonisolated struct DemoFinanceState: Codable, Sendable {
    var nextTransactionID: Int
    var accounts: [DemoAccountRecord]
    let categories: [DemoCategoryRecord]
    var transactions: [DemoTransactionRecord]
}

nonisolated struct DemoAccountRecord: Codable, Sendable {
    let id: Int
    let userId: Int
    var name: String
    var emoji: String
    var balance: String
    var currency: String
    let createdAt: String
    var updatedAt: String
}

nonisolated struct DemoCategoryRecord: Codable, Sendable {
    let id: Int
    let name: String
    let emoji: String
    let isIncome: Bool
}

nonisolated struct DemoTransactionSeed: Decodable, Sendable {
    let id: Int
    let accountId: Int
    let categoryId: Int
    let amount: String
    let daysAgo: Int
    let hour: Int
    let minute: Int
    let comment: String?
}

nonisolated struct DemoTransactionRecord: Codable, Sendable {
    let id: Int
    let accountId: Int
    let categoryId: Int
    let amount: String
    let transactionDate: Date
    let comment: String?
    let createdAt: Date
    let updatedAt: Date
}
