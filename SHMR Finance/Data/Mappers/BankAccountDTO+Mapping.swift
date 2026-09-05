//
//  BankAccountDTO+Mapping.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 15.07.2026.
//

import Foundation

nonisolated extension BankAccountDTO {
    func toDomain() throws -> BankAccount {
        guard let balance = Decimal(
            string: balance,
            locale: AppLocale.posix
        ) else {
            throw BankAccountMappingError.invalidBalance(balance)
        }

        return BankAccount(
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

nonisolated enum BankAccountMappingError:
    LocalizedError,
    Sendable {
    case invalidBalance(String)

    var errorDescription: String? {
        switch self {
        case let .invalidBalance(balance):
            String(
                format: AppLocalization.string(
                    localized: "Некорректный баланс счёта: %@."
                ),
                balance
            )
        }
    }
}
