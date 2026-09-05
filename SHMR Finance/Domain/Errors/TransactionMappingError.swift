//
//  TransactionMappingError.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 15.07.2026.
//

import Foundation

nonisolated enum TransactionMappingError:
    LocalizedError,
    Sendable {
    case accountNotFound(id: Int)
    case categoryNotFound(id: Int)
    case invalidAmount(String)
    case invalidBalance(String)
    case unexpectedAccount(expectedID: Int, actualID: Int)

    var errorDescription: String? {
        switch self {
        case let .accountNotFound(id):
            String(
                format: AppLocalization.string(
                    localized: "Счёт с идентификатором %lld не найден."
                ),
                Int64(id)
            )
        case let .categoryNotFound(id):
            String(
                format: AppLocalization.string(
                    localized: "Статья с идентификатором %lld не найдена."
                ),
                Int64(id)
            )
        case let .invalidAmount(amount):
            String(
                format: AppLocalization.string(
                    localized: "Некорректная сумма операции: %@."
                ),
                amount
            )
        case let .invalidBalance(balance):
            String(
                format: AppLocalization.string(
                    localized: "Некорректный баланс счёта: %@."
                ),
                balance
            )
        case let .unexpectedAccount(expectedID, actualID):
            String(
                format: AppLocalization.string(
                    localized: "Сервер вернул счёт %1$lld вместо счёта %2$lld."
                ),
                Int64(actualID),
                Int64(expectedID)
            )
        }
    }
}
