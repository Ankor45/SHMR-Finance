//
//  BankAccount.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 13.07.2026.
//

import Foundation

nonisolated struct BankAccount: Identifiable, Codable, Equatable, Sendable {
    let id: Int
    let userId: Int
    let name: String
    let emoji: String
    var balance: Decimal
    let currency: String
    let createdAt: String
    var updatedAt: String
}
