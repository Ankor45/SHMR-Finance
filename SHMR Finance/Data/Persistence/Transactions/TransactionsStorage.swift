//
//  TransactionsStorage.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

nonisolated protocol TransactionsStorage: Sendable {
    func get(
        accountId: Int,
        from: Date,
        to: Date
    ) async throws -> [Transaction]
}
