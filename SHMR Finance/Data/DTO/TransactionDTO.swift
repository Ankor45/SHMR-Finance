//
//  TransactionDTO.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 15.07.2026.
//

import Foundation

nonisolated struct TransactionDTO: Decodable, Sendable {
    let id: Int
    let accountId: Int
    let categoryId: Int
    let amount: String
    let transactionDate: Date
    let comment: String?
    let createdAt: Date
    let updatedAt: Date
}
