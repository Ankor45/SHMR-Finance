//
//  DemoFinanceRecord+DTO.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 04.09.2026.
//

nonisolated extension DemoAccountRecord {
    var dto: BankAccountDTO {
        BankAccountDTO(
            id: id,
            userId: userId,
            name: name,
            emoji: emoji,
            balance: balance,
            currency: currency,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

nonisolated extension DemoCategoryRecord {
    var dto: CategoryDTO {
        CategoryDTO(
            id: id,
            name: name,
            emoji: emoji,
            isIncome: isIncome
        )
    }
}

nonisolated extension DemoTransactionRecord {
    var dto: TransactionDTO {
        TransactionDTO(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func responseDTO(
        in state: DemoFinanceState
    ) throws -> TransactionResponseDTO {
        guard let account = state.accounts.first(
            where: { $0.id == accountId }
        ) else {
            throw FinanceStorageError.accountNotFound(id: accountId)
        }
        guard let category = state.categories.first(
            where: { $0.id == categoryId }
        ) else {
            throw TransactionMappingError.categoryNotFound(id: categoryId)
        }

        return TransactionResponseDTO(
            id: id,
            account: AccountBriefDTO(
                id: account.id,
                name: account.name,
                emoji: account.emoji,
                balance: account.balance,
                currency: account.currency
            ),
            category: category.dto,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
