//
//  TransactionResponseDTO.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

nonisolated struct TransactionResponseDTO: Decodable, Sendable {
    let id: Int
    let account: AccountBriefDTO
    let category: CategoryDTO
    let amount: String
    let transactionDate: Date
    let comment: String?
    let createdAt: Date
    let updatedAt: Date
}
