//
//  BankAccountDTO.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 15.07.2026.
//

import Foundation

nonisolated struct BankAccountDTO: Decodable, Sendable {
    let id: Int
    let userId: Int
    let name: String
    let emoji: String
    let balance: String
    let currency: String
    let createdAt: String
    let updatedAt: String
}
