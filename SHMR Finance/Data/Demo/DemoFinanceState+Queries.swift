//
//  DemoFinanceState+Queries.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 04.09.2026.
//

import Foundation

nonisolated extension DemoFinanceState {
    func categoryDTOs(
        direction: Direction? = nil
    ) -> [CategoryDTO] {
        categories
            .filter { category in
                guard let direction else { return true }
                return category.isIncome == (direction == .income)
            }
            .map(\.dto)
    }

    func accountDTOs() -> [BankAccountDTO] {
        accounts.map(\.dto)
    }

    func transactionDTOs(
        accountID: Int,
        from: Date,
        to: Date
    ) throws -> [TransactionResponseDTO] {
        guard accounts.contains(where: { $0.id == accountID }) else {
            throw FinanceStorageError.accountNotFound(id: accountID)
        }

        return try transactions
            .filter {
                $0.accountId == accountID
                    && $0.transactionDate >= from
                    && $0.transactionDate <= to
            }
            .sorted { $0.transactionDate > $1.transactionDate }
            .map { try $0.responseDTO(in: self) }
    }
}
